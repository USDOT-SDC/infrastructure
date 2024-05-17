import json
import sys
import boto3
# from boto3 import client
import datetime
import uuid


def iam_client():
  return boto3.client('iam')

def get_tag_value_from_key(key, tags):
  for tag in tags:
    if tag.get("Key", False) == key:
      return tag.get("Value", False)

def sts_client():
  return boto3.client('sts')

def json_converter(o):
  if isinstance(o, datetime.datetime):
    return o.__str__()

def get_uuid():
  return str(uuid.uuid4())

def lambda_handler(event, context):
    
    # check that username was passed
    username = event.get("queryStringParameters", False).get("username", False)
    if not username:
        sys.exit("No username was found in the queryStringParameters")
    print(f"Username: {username}")
    
    # check that pin was passed
    user_pin = event.get("queryStringParameters", False).get("pin", False)
    if not user_pin:
        sys.exit("No pin was found in the queryStringParameters")
    print(f"User PIN: {user_pin}")
    
    
    # get the pin from the role
    role_name = f"user_{username}"
    response = iam_client().list_role_tags(RoleName=role_name)
    tags = response.get("Tags", False)
    if not tags:
        sys.exit("No tags were found on the IAM Role")
    role_pin = get_tag_value_from_key("pin", tags)
    if not role_pin:
        sys.exit("No tag:pin was found on the IAM Role")
    
    # check the user pin against the role pin
    if user_pin != role_pin:
        sys.exit("Incorrect PIN")

    # get the account id, role arn and uuid
    account_id = sts_client().get_caller_identity()['Account']
    role_arn= f"arn:aws:iam::{account_id}:role/{role_name}" 
    unique_id = get_uuid()

    # assume the role and get the assumed_role
    assumed_role = sts_client().assume_role(
        RoleArn=role_arn,
        RoleSessionName=unique_id,
        DurationSeconds=3600
    )
    
    # get the credentials from the assumed_role and make them json
    credentials = assumed_role['Credentials']
    credentials = json.dumps(credentials, default=json_converter)
    print("credentials: " + credentials)

    # return the credentials as 
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": credentials,
        "isBase64Encoded": False
    }
