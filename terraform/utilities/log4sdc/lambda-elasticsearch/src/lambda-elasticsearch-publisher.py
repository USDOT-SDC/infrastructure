import boto3
import json
import requests
from requests_aws4auth import AWS4Auth
import datetime
import os


region = 'us-east-1' # For example, us-west-1
service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

    
host = os.environ.get('ELASTICSEARCH_URL')
url = host + '/log4sdc-index/log'


def lambda_handler_to_sns(event, context):
    account_num = os.environ.get('AWS_ACCOUNT_NUM')
    topicArn = f'arn:aws:sns:us-east-1:{account_num}:log4sdc-alert'
    sns_client = boto3.client('sns')
    sns_client.publish(TopicArn=topicArn,
        Message="message text",
        Subject="subject used in emails only")


def lambda_handler(event, context):
    #print(event)

    # Event for testing - if missing
    if not 'Records' in event:
        event = {'Records': [{'messageId': 'b8f8c2a0-6424-48da-8391-74234a860da4', 'receiptHandle': 'AQEBrsa+Nly24N1RCD1jvCHYjw8Jyhv3XdJNet99FkWjyQBw5V2IAmOaRiCg+oG6ZE76TIbOzlpw9/n2s5fm1s5L2YNjcKBiIZu21wvTw6zn47QKKIY9b8M3VQXbfx3g5QySE3jlwavMiiUIN04+WnUSqansWfU94/cF5P2USCz/yfRHX3wmQMR/ktWqPd5g2KGgQyYxk3XG0+A+ugZRZ76xVDg1h/mGj251qgVA2ckZan++40t7i1YMHPHmgX8rtF1HlLaYUn0voEXrl2BxiHgVVgqVrHcRO6WlcX0A0zlwWqjH4KwgcwKA/aD/kNC5C8H4kSBJyqjzdPAKKISlxEEnYAlxUDyArqzDjhvOg5KXlRPfkaolUWp6fSallKDn83Bt', 'body': '{\r\n            "time" : "2021-10-12T18:51:40 0000",\r\n            "level" : "FATAL",\r\n            "project" : "CVP",\r\n            "team" : "CVP-NYC",\r\n            "component" : "log4sdc-elasticsearch-publisher",\r\n            "summary" : "Unable to load messages into WYDOT S3 drop zone bucket",\r\n            "userdata" : "Proof of concept development"\r\n}', 'attributes': {'ApproximateReceiveCount': '1', 'AWSTraceHeader': 'Root=1-6165f185-ef64ace37a37709edc59354c', 'SentTimestamp': '1634070917584', 'SenderId': 'AROAXLHDN5KB2FMAZSGMA:BackplaneAssumeRoleSession', 'ApproximateFirstReceiveTimestamp': '1634070917585'}, 'messageAttributes': {}, 'md5OfBody': '5cd2ab4261a41f63d402ab6b68fabff2', 'eventSource': 'aws:sqs', 'eventSourceARN': 'arn:aws:sqs:us-east-1:1234567890:log4sdc-sqs', 'awsRegion': 'us-east-1'}]}

    
    for r in event['Records']:
        headers = { "Content-Type": "application/json" }
        data = json.loads(r['body'])
        data['time'] = datetime.datetime.now().astimezone().isoformat()
        
        #if not 'Records' in event:
        #    data = {
        #                "time" : datetime.datetime.now().astimezone().isoformat(),
        #                "level" : "INFO",
        #                "project" : "WAZE",
        #                "team" : "WAZE-WAZE",
        #                "component" : "log4sdc-elasticsearch-publisher",
        #                "summary" : "another test message",
        #                "userdata" : "Proof of concept development"
        #    }
        
        print(data)
        
        res = requests.post(url, auth=awsauth, headers=headers, data=json.dumps(data))
        print(res)
        print(res.status_code)
        print(json.loads(res.text))
    
    response = {
        'statusCode': res.status_code,
        'body': res.text
    }
    
    return response


