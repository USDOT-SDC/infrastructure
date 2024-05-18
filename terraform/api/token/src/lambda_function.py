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


def int_from_str(string: str) -> int | bool:
    try:
        return int(string)
    except ValueError as e:
        print(f"{string} cannot be converted to an int: {e}")
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

    # check that pin was passed
    user_pin: str | bool = event.get("queryStringParameters", False).get("pin", False)
    if not user_pin:
        sys.exit("No pin was found in the queryStringParameters")
    # print(f"User PIN: {user_pin}")

    # get the pin from the role
    role_name: str = f"user_{username}"
    response: dict = iam_client().list_role_tags(RoleName=role_name)
    tags: list | bool = response.get("Tags", False)
    if not tags:
        sys.exit("No tags were found on the IAM Role")
    role_pin: str = get_tag_value_from_key("pin", tags)
    if not role_pin:
        sys.exit("No tag:pin was found on the IAM Role")

    # check that both pins are int-able
    user_pin = int_from_str(user_pin)
    if not user_pin:
        sys.exit("The user PIN was not int-able")
    role_pin = int_from_str(role_pin)
    if not role_pin:
        sys.exit("The role PIN was not int-able")

    # check the user pin against the role pin
    if user_pin != role_pin:
        sys.exit("Incorrect PIN")

    # get the account id, role arn and uuid
    account_id: str = sts_client().get_caller_identity().get("Account", "")
    role_arn: str = f"arn:aws:iam::{account_id}:role/{role_name}"
    unique_id: str = get_uuid()

    # assume the role and get the assumed_role
    assumed_role: dict = sts_client().assume_role(RoleArn=role_arn, RoleSessionName=unique_id, DurationSeconds=3600)

    # get the credentials from the assumed_role and make them json str
    credentials: dict = assumed_role.get("Credentials", {})
    print(f"Username: {username}, User PIN: {user_pin}, AccessKeyId: {credentials.get("AccessKeyId", "")}")
    credentials: str = json.dumps(credentials, default=json_converter)
    # print("credentials: " + credentials)

    # return the credentials
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": credentials,
        "isBase64Encoded": False,
    }
