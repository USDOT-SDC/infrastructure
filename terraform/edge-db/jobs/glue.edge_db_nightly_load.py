'''
=============================================================================================================================
Job Imports & Init
=============================================================================================================================
'''

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

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
# Set Spark Configurations
sc = SparkContext()
sc.setLogLevel("DEBUG")
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)
dynamodb = boto3.resource('dynamodb')


'''
=============================================================================================================================
Function Declarations
=============================================================================================================================
'''

def scan_db(table, scan_kwargs=None):
    """
    Overview:
        Get all records of the dynamodb table where the FilterExpression holds true
        
    Function Details:
        :param: scan_kwargs: dict: Used to pass filter conditions, know more about kwargs- geeksforgeeks.org/args-kwargs-python/
        :param: table: string: Dynamodb table name
        :return: records: dict: List of DynamoDB records returned.
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
    """
    Overview:
        Iterates over all entries of a specified internal table and attempts to find outlier values, via Standard Deviation, when compared to data existing on the edge-clone table (the same table that exists on the edge side). This function doesn't reject any entry, but serves to warn Data Stewards if any entry seems unsual based on the previously published data.
        
    Function Details:
        :param: dyf_source: Spark Dynamic Frame: A dynamic spark dataframe of the internal table (table containing potential outlier values). 
        :param: tableName: string: The corressponding name of the internal table that 'dyf_source' is based on.
        :param: targetDBSchema: string: Target Schema on the EdgeDB (schema in which the edge-clone table lives).
        :param: databaseName: string: Name of the database in which the edge-clone table lives.
        :optional_param: stdDev_threshold: string: The Standard Deviation threshold in which an entry is considered an outlier. Default set to 3 Standard Deviations.
        :return: boolean, list: Returns a boolean value if outlier values were detected and a corressponding list of outlier values (if any).
    """
    outlier_values = {}
    outlier_detection = False
    df_source = dyf_source.toDF()
    
    # DEBUG/Testing Lines Below:
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
    """
    Overview:
        A function to send out emails via AWS SES.
        
    Function Details:
        :param: listOfRecipients: list of strings: A list of recipient email addresses.
        :param: emailContent: string: The content of the email. HTML-formatted email passed in as a string.
        :optional_param: subject: string: The title/subject of the email. Defaults to 'Schema Change Rejection'.
        :return: None
    """
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


'''
=============================================================================================================================
Main Script
=============================================================================================================================
'''

''' -------------- DynamoDB Section --------------'''
kwargs = {
        'FilterExpression': Attr('RequestType').eq('Table') & Attr('RequestReviewStatus').eq('Approved') # Filter Expression for DynamoDB Scan. Get entries where status = 'approved'
    }
requests = scan_db('dev-RequestExportTable', kwargs) #Execute filter expression, defined in 'kwargs', on DynamoDB table 'dev-RequestExportTable'.
print("Approved Export Requests: \n", requests) #Print Approved Export Requets in logs to show what entries have been looked at.

# 1. check schema against schema attribute
for request in requests:
    approved_schema = str(request['TableSchema'])
    tableName = str(request["TableName"])
    tableName_glue = str(request["TableName"]).replace('-', '_').replace('.', '_').strip() #'.' and '-' characters have been replaced with '_' to comply with Glue Catalog needs.
    sourceSchema_glue = str(request["SourceDatabaseSchema"]).replace('-', '_').replace('.', '_').strip()  #'.' and '-' characters have been replaced with '_' to comply with Glue Catalog needs.
    targetSchema_glue = str(request["TargetDatabaseSchema"]).replace('-', '_').replace('.', '_').strip()  #'.' and '-' characters have been replaced with '_' to comply with Glue Catalog needs.
    sourceSchema = str(request["SourceDatabaseSchema"]).strip()  #Used for direct JDBC connections (no glue catalog)
    targetSchema = str(request["TargetDatabaseSchema"]).strip()  #Used for direct JDBC connections (no glue catalog)
    databaseName_glue = str(request["DatabaseName"]).replace('-', '_').replace('.', '_').strip()  #'.' and '-' characters have been replaced with '_' to comply with Glue Catalog needs.
    databaseName = str(request["DatabaseName"])
    userEmail = str(request["UserEmail"]).strip()
    listOfPOC = str(request["ListOfPOC"]).strip()
    
    # Create dynamic frame based on the approved table table from DynamoDb record. Retrieves table from the internal database.
    datasource0 = glueContext.create_dynamic_frame.from_catalog(database = "dev.sdc.dot.gov.research-team.data-export", table_name = databaseName_glue + "_" + sourceSchema_glue + "_" + tableName_glue, transformation_ctx = "datasource0")

    schema = datasource0._jdf.schema().treeString() #Isolates schema string of internal DB table for schema comparison based on initial/approved schema (part of approval record). 
    
    print("Internal Schema: ", schema) #Print Internal Table Schema to Logs.
    print("Approved Schema: ", approved_schema) #Print Approved Table Schema to Logs.
    print("No Change in Schema: ", detect_schema_change(schema, approved_schema)) #Print Schema Change Function Output to logs.
    
    # If schema has changed, Resubmit for approval, by updating previously approved DynamoDB record, to 'rejected' status.
    if not detect_schema_change(schema, approved_schema):
        #Send an email to Users of Schema Rejection
        email_recipients = [userEmail]
        emailContent = "<br/>Export to EdgeDB has detected a schema change for the previously approved table: <b>" + tableName + "</b> for database <b>" + databaseName + ".</b> Please submit another export request to approve the new table schema at https://portal.sdc.dot.gov.<b>" + "</b>"
        send_notification(email_recipients,emailContent)
        # Update corressponding Dynamodb entry to status: "rejected"
        exportRequests_table = dynamodb.Table('dev-RequestExportTable')
        response = exportRequests_table.update_item(
            Key={
                'S3KeyHash': request["S3KeyHash"],
                'RequestedBy_Epoch': request["RequestedBy_Epoch"]
            },
            UpdateExpression="set RequestReviewStatus = :r",
            ExpressionAttributeValues={
                ':r': 'Rejected'
            }
        )

    else:
        try:
            outlier_flag, outlier_values = qa_function(datasource0, tableName_glue, targetSchema_glue, databaseName_glue)
        except Exception as e:
            print("Unable to determine target outlier values. Function failed with: ", e)
            outlier_flag = False
            pass
        if outlier_flag:         
            #Send an email to approvers of outlier values detected. QA Email.
            email_recipients = [listOfPOC]
            emailContent = "<br/>Export to EdgeDB has detected the following values significantly higher or lower (longer or shorter) than average for table: <b>" + tableName + "</b> for database <b>" + databaseName + ":</b>" + str(outlier_values) + " Please notify sdc-support@dot.gov if these values are not acceptable.<b>" + "</b>"
            emailSubject = 'Export Notification: Anomalies Detected'
            send_notification(email_recipients,emailContent, emailSubject)
            print(outlier_values)
        
    # write internal table dynamic frame to EdgeDB (overwrite edge clone table with new data). Overwrites table to handle any existing entries that were modified.
    dbtable = targetSchema + "." + tableName
    # datasink1 = glueContext.write_dynamic_frame.from_jdbc_conf(frame = datasource0, catalog_connection = "Data Export Edge Acme DB", connection_options = {"dbtable": dbtable, "database": databaseName}, transformation_ctx = "datasink1")

    jdbcDF = datasource0.toDF()
    print(f'Dataframe to be written {jdbcDF.head()}')
    #JDBC Connection to EdgeDB
    #TODO: Get Admin Credentials into SSM Parameter Store.
    x = jdbcDF.write.format("jdbc") \
    .option("url", f"jdbc:postgresql://aurora-dataexport-edge-instance-1.cbldpsthn7bv.us-east-1.rds.amazonaws.com:5432/" + databaseName) \
    .option("dbtable", dbtable) \
    .option("user", "sdc_admin") \
    .option("password", "password") \
    .mode("overwrite").option("truncate", "true") \
    .save()

job.commit()