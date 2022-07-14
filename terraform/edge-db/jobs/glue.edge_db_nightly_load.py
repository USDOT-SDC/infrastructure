import sys
import boto3

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from boto3.dynamodb.conditions import Attr, Key
from pyspark.sql.types import *
from pyspark.sql.functions import mean as _mean, stddev as _stddev, col, length as length
from pyspark.sql import *


# dynamodb_resource = boto3.resource('dynamodb')
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)
dynamodb = boto3.resource('dynamodb')
 

def scan_db(table, scan_kwargs=None):
    """
    Get all records of the dynamodb table where the FilterExpression holds true
    :param scan_kwargs: Used to pass filter conditions, know more about kwargs- geeksforgeeks.org/args-kwargs-python/
    :type scan_kwargs: dict
    :param table: dynamodb table name
    :type table: str
    :return: list of records
    :rtype: dict
    """
    if scan_kwargs is None:
        scan_kwargs = {}
    table = dynamodb.Table(table)

    complete = False
    records = []
    while not complete:
        try:
            response = table.scan(**scan_kwargs)
        except botocore.exceptions.ClientError as error:
            raise Exception('Error quering DB: {}'.format(error))

        records.extend(response.get('Items', []))
        next_key = response.get('LastEvaluatedKey')
        scan_kwargs['ExclusiveStartKey'] = next_key

        complete = True if next_key is None else False
    return records

def detect_schema_change(string1, string2):
    '''
    Overview:
        A function that takes in two string schemas of two pyspark dataframes and compares
        them to see if they're equivalent. The string schema inputs must match
        the string output of Pyspark's printSchema() function.
        An example string schema input can be found below: 
            
        root
        |-- name: string (nullable = true)
        |-- age: long (nullable = true)
    
    Function Details:
        :param: string1: string: The schema of the first pyspark dataframe.
        :param: string2: string: The schema of the secondary pyspark dataframe.
        :return: boolean: Whether the schemas are equivalent or not.
        
    '''
    string1_map = {} #Initialize schema object that will be built in function.
    string2_map = {} #Initialize schema object that will be built in function.
    
    '''Split the raw schema string into an array of attributes'''
    string1_arr = string1.split('|--') 
    string2_arr = string2.split('|--')
    del string1_arr[0]
    del string2_arr[0]
    
    '''
    Return False if number of attributes from schema 1
    doesn't equal number of attributes from schema 2.
    '''
    if len(string1_arr) != len(string2_arr):
        return False
    else:
        '''If number of attributes are same, build schema objects for comparison.'''
        for attr1, attr2 in zip(string1_arr, string2_arr):
            attr1.replace("\n", "")
            attr2.replace("\n", "")
            
            attr1_arr = attr1.split(':')
            attr2_arr = attr2.split(':')
            
            string1_map[attr1_arr[0].strip()] = attr1_arr[1].strip() 
            string2_map[attr2_arr[0].strip()] = attr2_arr[1].strip() 
       
        '''Handle Schema Objects Comparison''' 
        for attr1 in string1_map:
            if attr1 in string2_map:
                attr1_value = string1_map[attr1]
                attr2_value = string2_map[attr1]
                if attr1_value != attr2_value:
                    return False #Return False if value for key does not match.
            else:
                return False #Return False if key doesn't exist in both schemas.
        return True
        
def qa_function(dyf_source, tableName, targetDBSchema, databaseName, stdDev_threshold=3):
    outlier_values = {}
    outlier_detection = False
    df_source = dyf_source.toDF()
    
    # example_data = [('Bob', 'Smith', 1, 5.5),('Tom','Caesar',20, 20.6),('Steve','Patel',15, 43.66),('Moe','Shmo',14,37.44),('Justin','Fox', 5, 20.5), ('Kyle','Smith', 10, 26.7)] 
    # df_old = spark.createDataFrame(example_data, ['first_name','last_name','intCol', 'floatCol'])

    dyf_target = glueContext.create_dynamic_frame.from_catalog(database = "dev.sdc.dot.gov.research-team.data-export.edge", table_name = databaseName + "_" + targetDBSchema + "_" + tableName, transformation_ctx = "dyf_target")
    df_old = dyf_target.toDF()
    
    column_list = df_source.columns
    for column in column_list:
        if str(df_old.schema[column].dataType) == 'StringType':
            temp_column_name = column+'_tokenized' 
            tempDF_old = df_old.withColumn(temp_column_name, length(column))
            df_stats = tempDF_old.select(
                _mean(col(temp_column_name)).alias('mean'),
                _stddev(col(temp_column_name)).alias('std')
            ).collect()
            
            mean = df_stats[0]['mean']
            std = df_stats[0]['std']
            lowerBound = mean - (std*stdDev_threshold)
            upperBound = mean + (std*stdDev_threshold)
            
            tempDF_new = df_source.withColumn(temp_column_name, length(column))
            
            outlierDF = tempDF_new.filter((tempDF_new[temp_column_name] < lowerBound) | (tempDF_new[temp_column_name] > upperBound))
            outlier_list = outlierDF.select(column).rdd.map(lambda x : x[0]).collect()
            if not outlier_detection:
                outlier_detection = True if outlier_list else False
            if outlier_list:
                outlier_values[column]= outlier_list
            
        elif str(df_old.schema[column].dataType) in ['IntegerType','FloatType','LongType','DoubleType','ShortType']:
            df_stats = df_old.select(
                _mean(col(column)).alias('mean'),
                _stddev(col(column)).alias('std')
            ).collect()
            
            mean = df_stats[0]['mean']
            std = df_stats[0]['std']
            lowerBound = mean - (std*3)
            upperBound = mean + (std*3)
            
            outlierDF = df_source.filter((df_source[column] < lowerBound) | (df_source[column] > upperBound))
            outlier_list = outlierDF.select(column).rdd.map(lambda x : x[0]).collect()
            if not outlier_detection:
                outlier_detection = True if outlier_list else False
            if outlier_list:
                outlier_values[column]= outlier_list
        else:
            continue
    return outlier_detection, outlier_values
        
def send_notification(listOfRecipients, emailContent, subject = 'Export Notification: Schema Change Rejection'):
    ses_client = boto3.client('ses')
    sender = 'sdc-support@dot.gov'

    try:
        response = ses_client.send_email(
            Destination={
                'BccAddresses': [
                ],
                'CcAddresses': [
                ],
                'ToAddresses': listOfRecipients,
            },
            Message={
                'Body': {
                    'Html': {
                        'Charset': 'UTF-8',
                        'Data': emailContent,
                    },
                    'Text': {
                        'Charset': 'UTF-8',
                        'Data': 'This is the notification message body in text format.',
                    },
                },
                'Subject': {
                    'Charset': 'UTF-8',
                    'Data': subject,
                },
            },
            Source=sender
        )
    except Exception as e:
        print(e)

# get list of tables from dynamodb where status = 'approved'
kwargs = {
        'FilterExpression': Attr('RequestType').eq('table') & Attr('RequestReviewStatus').eq('Approved')
    }
# 1. check schema against schema attribute
for request in scan_db('dev-RequestExportTable', kwargs):
    approved_schema = str(request['TableSchema'])
    tableName = str(request["TableName"]).strip()
    sourceSchema = str(request["SourceDatabaseSchema"]).strip()
    targetSchema = str(request["TargetDatabaseSchema"]).strip()
    databaseName = str(request["DatabaseName"]).strip()
    userEmail = str(request["UserEmail"]).strip()
    listOfPOC = str(request["ListOfPOC"]).strip()
    
    # create dynamic frame from approved table
    datasource0 = glueContext.create_dynamic_frame.from_catalog(database = "dev.sdc.dot.gov.research-team.data-export", table_name = databaseName + "_" + sourceSchema + "_" + tableName, transformation_ctx = "datasource0")

    schema = datasource0._jdf.schema().treeString()
    
    print("schema: ", schema)
    print("approved schema: ", approved_schema)
    
    # if schema changes, resubmit for approval
    if not detect_schema_change(schema, approved_schema):
        # email user of rejection
        email_recipients = [userEmail]
        emailContent = "<br/>Export to EdgeDB has detected a schema change for the previously approved table: <b>" + tableName + "</b> for database <b>" + databaseName + ".</b> Please submit another export request to approve the new table schema at https://portal.sdc.dot.gov.<b>" + "</b>"
        send_notification(email_recipients,emailContent)
        # update dynamodb entry to status: "rejected"
        exportRequests_table = dynamodb.Table('dev-RequestExportTable')
        response = exportRequests_table.update_item(
            Key={
                'S3KeyHash': request["S3KeyHash"],
                'RequestedBy_Epoch': request["RequestedBy_Epoch"]
            },
            UpdateExpression="set RequestReviewStatus = :r",
            ExpressionAttributeValues={
                ':r': 'Rejected',
            }
        )
        continue

    # e-mail approvers any outlier values detected
    try:
        outlier_flag, outlier_values = qa_function(datasource0, tableName, targetSchema, databaseName)
    except Exception as e:
        print("Unable to determine target outlier values. Function failed with: ", e)
    else:
        if outlier_flag:
            email_recipients = [listOfPOC]
            emailContent = "<br/>Export to EdgeDB has detected the following values significantly higher or lower (longer or shorter) than average for table: <b>" + tableName + "</b> for database <b>" + databaseName + ":</b>" + str(outlier_values) + " Please notify sdc-support@dot.gov if these values are not acceptable.<b>" + "</b>"
            emailSubject = 'Export Notification: Anomalies Detected'
            send_notification(email_recipients,emailContent, emailSubject)
            print(outlier_values)
        
    # write table to edge db
    dbtable = targetSchema + "." + tableName
    # datasink1 = glueContext.write_dynamic_frame.from_jdbc_conf(frame = datasource0, catalog_connection = "Data Export Edge Acme DB", connection_options = {"dbtable": dbtable, "database": databaseName}, transformation_ctx = "datasink1")

    jdbcDF = datasource0.toDF()

    x = jdbcDF.write.format("jdbc") \
    .option("url", f"jdbc:postgresql://aurora-dataexport-edge-instance-1.cbldpsthn7bv.us-east-1.rds.amazonaws.com:5432/" + databaseName) \
    .option("dbtable", dbtable) \
    .option("user", "sdc_admin") \
    .option("password", "password") \
    .mode("overwrite").option("truncate", "true") \
    .save()

job.commit()