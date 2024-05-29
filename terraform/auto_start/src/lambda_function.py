import json
import os
from typing import Any
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError


class DynamoDBClient:
    def __init__(self, table_name, region_name="us-east-1"):
        self.table_name = table_name
        self.dynamodb = boto3.resource("dynamodb", region_name=region_name)
        self.table = self.dynamodb.Table(table_name)
        self.client = boto3.client("dynamodb", region_name=region_name)

    def add_item(self, item):
        try:
            response = self.table.put_item(Item=item)
            return response
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def get_item(self, key):
        try:
            response = self.table.get_item(Key=key)
            return response.get("Item", None)
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def update_item(self, key, update_expression, expression_attribute_values):
        try:
            response = self.table.update_item(
                Key=key,
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_attribute_values,
                ReturnValues="UPDATED_NEW",
            )
            return response
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def delete_item(self, key):
        try:
            response = self.table.delete_item(Key=key)
            return response
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def query(self, key_condition_expression, expression_attribute_values):
        try:
            paginator = self.client.get_paginator("query")
            response_iterator = paginator.paginate(
                TableName=self.table_name,
                KeyConditionExpression=key_condition_expression,
                ExpressionAttributeValues=expression_attribute_values,
            )
            items = []
            for page in response_iterator:
                items.extend(page.get("Items", []))
            return items
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def scan(self, filter_expression=None, expression_attribute_values=None):
        try:
            paginator = self.client.get_paginator("scan")
            scan_args = {"TableName": self.table_name}
            if filter_expression:
                scan_args["FilterExpression"] = filter_expression
            if expression_attribute_values:
                scan_args["ExpressionAttributeValues"] = expression_attribute_values

            response_iterator = paginator.paginate(**scan_args)
            items = []
            for page in response_iterator:
                items.extend(page.get("Items", []))
            return items
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def convert_dynamodb_json(self, dynamodb_json):
        def convert_value(value):
            if isinstance(value, dict) and len(value) == 1:
                for k, v in value.items():
                    if k == "S":  # String
                        return str(v)
                    elif k == "N":  # Number
                        return int(v) if "." not in v else float(v)
                    elif k == "BOOL":  # Boolean
                        return bool(v)
                    elif k == "NULL":  # Null
                        return None
                    elif k == "L":  # List
                        return [convert_value(i) for i in v]
                    elif k == "M":  # Map
                        return self.convert_dynamodb_json(v)
                    elif k == "SS":  # String Set
                        return set(str(i) for i in v)
                    elif k == "NS":  # Number Set
                        return set(int(i) if "." not in i else float(i) for i in v)
                    # Add other DynamoDB data types if needed
            return value

        if isinstance(dynamodb_json, dict):
            return {k: convert_value(v) for k, v in dynamodb_json.items()}
        elif isinstance(dynamodb_json, list):
            return [convert_value(i) for i in dynamodb_json]
        else:
            return dynamodb_json

    def convert_dynamodb_json_list(self, dynamodb_json_list: list[Any]) -> list:
        json_list: list = []
        for dynamodb_json in dynamodb_json_list:
            json_list.append(self.convert_dynamodb_json(dynamodb_json))
        return json_list


class EC2Manager:
    def __init__(self, region_name="us-east-1"):
        self.ec2 = boto3.client("ec2", region_name=region_name)

    def start_instances(self, instance_ids):
        try:
            response = self.ec2.start_instances(InstanceIds=instance_ids)
            return response
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"
        except Exception as e:
            return f"Error starting instances: {e}"


def get_env() -> str:
    return os.getenv("ENV", "dev")


def get_region() -> str:
    return os.getenv("REGION", "us-east-1")


def get_dynamodb_table() -> str:
    return os.getenv("DYNAMODB_TABLE", "instance_auto_start")


def dd(obj):
    print(json.dumps(obj, indent=4, default=str()))


def lambda_handler(event, context) -> None:
    # print(event)
    # print(context)
    client = DynamoDBClient(get_dynamodb_table())
    all_items = client.convert_dynamodb_json_list(client.scan())
    dd(all_items)


"""
# Example usage
if __name__ == "__main__":
    table_name = 'YourDynamoDBTableName'
    client = DynamoDBClient(table_name)

    # Example: Add an item
    item = {
        'PrimaryKey': '123',
        'Attribute1': 'Value1',
        'Attribute2': 'Value2'
    }
    print(client.add_item(item))

    # Example: Get an item
    key = {'PrimaryKey': '123'}
    print(client.get_item(key))

    # Example: Update an item
    update_expression = "SET Attribute1 = :val1"
    expression_attribute_values = {':val1': 'UpdatedValue1'}
    print(client.update_item(key, update_expression, expression_attribute_values))

    # Example: Delete an item
    print(client.delete_item(key))

    # Example: Query items (assuming table has a GSI with partition key 'PrimaryKey')
    key_condition_expression = "PrimaryKey = :pk"
    expression_attribute_values = {':pk': {'S': '123'}}
    print(client.query(key_condition_expression, expression_attribute_values))

    # Example: Scan all items
    all_items = client.scan()
    print(all_items)

    # Example: Start EC2 instances
    ec2_manager = EC2Manager()
    
    # Assuming DynamoDB items have an 'InstanceId' attribute
    instance_ids = [item['InstanceId']['S'] for item in all_items if 'InstanceId' in item]
    if instance_ids:
        print(ec2_manager.start_instances(instance_ids))
    else:
        print("No instance IDs found in DynamoDB table.")

"""
