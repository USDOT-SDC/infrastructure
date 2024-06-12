from boto3 import client
from typing import Any
import json
import sys
import uuid
import datetime


def iam_client() -> client:
    return client("iam")


def get_tag_value_from_key(key: str, tags: list[dict]) -> str | bool:
    for tag in tags:
        if tag.get("Key", False) == key:
            return tag.get("Value", False)
    return False


def sts_client() -> client:
    return client("sts")


def get_uuid() -> str:
    return str(uuid.uuid4())


def json_converter(o):
  if isinstance(o, datetime.datetime):
    return o.__str__()


def lambda_handler(event: dict, context: dict) -> dict[str, Any]:

    # check that username was passed
    username: str | bool = event.get("queryStringParameters", False).get("username", False)
    if not username:
        sys.exit("No username was found in the queryStringParameters")
    # print(f"Username: {username}")

    # check that user_key was passed
    user_key: str | bool = event.get("queryStringParameters", False).get("user_key", False)
    if not user_key:
        sys.exit("No user_key was found in the queryStringParameters")
    # print(f"User Key: {user_key}")

    # get the key from the role
    role_name: str = f"api_user_{username}"
    response: dict = iam_client().list_role_tags(RoleName=role_name)
    tags: list | bool = response.get("Tags", False)
    if not tags:
        sys.exit("No tags were found on the IAM Role")
    role_key: str = get_tag_value_from_key("key", tags)
    if not role_key:
        sys.exit("No tag:key was found on the IAM Role")

    # check the user key against the role key
    if user_key != role_key:
        sys.exit(f"An incorrect key was used. user_key:'{user_key}' != role_key:'{role_key}'")

    # get the account id, role arn and uuid
    account_id: str = sts_client().get_caller_identity().get("Account", "")
    role_arn: str = f"arn:aws:iam::{account_id}:role/{role_name}"
    unique_id: str = get_uuid()

    # assume the role and get the assumed_role
    assumed_role: dict = sts_client().assume_role(RoleArn=role_arn, RoleSessionName=unique_id, DurationSeconds=3600)

    # get the credentials from the assumed_role and make them json str
    credentials: dict = assumed_role.get("Credentials", {})
    print(f"Username: {username}, AccessKeyId: {credentials.get("AccessKeyId", "")}")
    credentials: str = json.dumps(credentials, default=json_converter)
    # print("credentials: " + credentials)

    # return the credentials
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": credentials,
        "isBase64Encoded": False,
    }
