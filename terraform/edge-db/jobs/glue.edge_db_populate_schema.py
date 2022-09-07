import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3
import os

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'WORKFLOW_NAME', 'WORKFLOW_RUN_ID'])
job.init(args["JOB_NAME"], args)
dynamodb = boto3.resource('dynamodb')

'''
=====================================================================================================================================
Pull Input Parameters from Glue Workflow
=====================================================================================================================================
'''
def get_workflow_params(args):
    """
    A function to retrieve Runtime GLUE WORKFLOW parameters
    """
    glue_client = boto3.client("glue")
    if "WORKFLOW_NAME" in args and "WORKFLOW_RUN_ID" in args:
        workflow_args = glue_client.get_workflow_run_properties(Name=args['WORKFLOW_NAME'], RunId=args['WORKFLOW_RUN_ID'])["RunProperties"]
        print("Found the following workflow args: \n{}".format(workflow_args))
        return workflow_args
    print("Unable to find run properties for this workflow!")
    return None
def get_runtime_param(args, arg): 
    """
    get_worfklow_param is delegated to verify if the given parameter is present in the job and return it. In case of no presence None will be returned
    """
    if args is None:
        return None
    return args[arg] if arg in args else None

run_properties = get_workflow_params(args)
print(f'Run Properties: {run_properties}')
S3KeyHash = get_runtime_param(run_properties, "S3KeyHash")
RequestedBy_Epoch = get_runtime_param(run_properties,"RequestedByEpoch")
databaseName = get_runtime_param(run_properties,"databaseName").replace('-', '_').replace('.', '_')
tableName = get_runtime_param(run_properties,"tableName").replace('-', '_').replace('.', '_')
internalSchema = get_runtime_param(run_properties,"internalSchema").replace('-', '_').replace('.', '_')
listOfPOC = get_runtime_param(run_properties,"listOfPOC").split(",")
userID = get_runtime_param(run_properties,"userID")
userEmail = get_runtime_param(run_properties,"userEmail").split(",")

'''
=====================================================================================================================================
Helper Function Declaration
=====================================================================================================================================
'''
def send_notification(listOfRecipients, emailContent):
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
                    'Data': 'SDC: Table Export Notification - Export Request',
                },
            },
            Source=sender
        )
    except Exception as e:
        print(e)

'''
=====================================================================================================================================
Retrieved Table Information & Schema. Convert Dynamic Frame to Dataframe.
=====================================================================================================================================
'''
try:
    # create dynamic frame from approved table
    datasource0 = glueContext.create_dynamic_frame.from_catalog(database = "dev.sdc.dot.gov.research-team.data-export", table_name = databaseName + "_" + internalSchema + "_" + tableName, transformation_ctx = "datasource0")
except:
    exportRequests_table = dynamodb.Table('dev-RequestExportTable')
    response = exportRequests_table.update_item(
        Key={
            'S3KeyHash': S3KeyHash,
            'RequestedBy_Epoch': RequestedBy_Epoch
        },
        UpdateExpression="set RequestReviewStatus = :r",
        ExpressionAttributeValues={
            ':r': 'Rejected',
        })
    emailContent = "<br/> The export to EdgeDB request made for the database table <b>" + tableName + "</b> in the database <b>" + databaseName + "</b> has failed. The table specified was not found in the selected database. As a result of the table not being found, the request has been automatically rejected.Please verify the table name and database name are correct in the request and submit a new table export request. If additional help is needed, please contact sdc-support@dot.gov."
    send_notification(userEmail, emailContent)
    os._exit(0)
    
try:    
    schema = datasource0._jdf.schema().treeString()
    df_source = datasource0.toDF()
    
    '''
    =====================================================================================================================================
    Update DynamoDB Record with Table Schema.
    =====================================================================================================================================
    '''
    exportRequests_table = dynamodb.Table('dev-RequestExportTable')
    response = exportRequests_table.update_item(
        Key={
            'S3KeyHash': S3KeyHash,
            'RequestedBy_Epoch': RequestedBy_Epoch
        },
        UpdateExpression="set TableSchema = :r",
        ExpressionAttributeValues={
            ':r': schema,
        }
    )
    
    '''
    =====================================================================================================================================
    Email Generation
    =====================================================================================================================================
    '''
    schema = schema.replace("|--","<br>&nbsp;&nbsp;")
    schema = schema.replace("root","")
    schema = "\n" + schema

    sample_data_df = df_source.sample(False, 0.1, seed=0).limit(5)
    sample_data_list = df_source.rdd.flatMap(lambda x:str(x)).collect()
    sample_data_string = ''.join(sample_data_list)
    sample_data_string = sample_data_string.replace("Row","<br>&nbsp;&nbsp;")
    
    emailContent = "<br/> An export to EdgeDB request has been made by <b>" + userID + "</b> for the database table <b>" + tableName + "</b> in the database <b>" + databaseName + "</b>.<br><br>The schema for the table is as follows: <b>" + schema + "</b><br><br>A sample of the data looks like the following: <b>" + sample_data_string + "</b>."
    
    send_notification(listOfPOC, emailContent)
    job.commit()

except:
    emailContent = "<br/> The export to EdgeDB request made for the database table <b>" + tableName + "</b> in the database <b>" + databaseName + "</b> has failed. Something has gone wrong within the export job. This is not an error of the requestor or human error."+"<br><br>Please contact sdc-support@dot.gov if you receive this email."
    send_notification(userEmail, emailContent)
