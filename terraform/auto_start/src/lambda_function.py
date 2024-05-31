import json
import os
import sys
from typing import Any
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError
from datetime import datetime, timedelta
from typing import Optional, Tuple

import pytz


def get_env() -> str:
    return os.getenv("ENV", "dev")


def get_region() -> str:
    return os.getenv("REGION", "us-east-1")


def get_ddbt_auto_start() -> str:
    return os.getenv("DDBT_AUTO_START", "instance_auto_start")


def get_ddbt_maintenance_windows() -> str:
    return os.getenv("DDBT_MAINTENANCE_WINDOW", "instance_maintenance_windows")


def round_dt(dt: datetime, minutes: int = 15) -> datetime:
    delta = timedelta(minutes=minutes)
    return datetime.min + round((dt - datetime.min) / delta) * delta


def dd(obj):
    print(json.dumps(obj, indent=4, default=str()))


class DynamoDBClient:
    def __init__(self, table_name, region_name=get_region()):
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

    def query(self, key_condition_expression, expression_attribute_values) -> list | str:
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

    def scan(self, filter_expression=None, expression_attribute_values=None) -> list | str:
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
        if isinstance(dynamodb_json, dict):
            return {k: self.convert_value(v) for k, v in dynamodb_json.items()}
        elif isinstance(dynamodb_json, list):
            return [self.convert_value(i) for i in dynamodb_json]
        else:
            return dynamodb_json

    def convert_value(self, value):
        # Lookup table for conversion
        conversion_lookup = {
            "S": str,
            "N": lambda v: int(v) if "." not in v else float(v),
            "BOOL": bool,
            "NULL": lambda v: None,
            "L": lambda v: [self.convert_value(i) for i in v],
            "M": self.convert_dynamodb_json,
            "SS": lambda v: set(str(i) for i in v),
            "NS": lambda v: set(int(i) if "." not in i else float(i) for i in v),
        }
        if isinstance(value, dict) and len(value) == 1:
            key, val = next(iter(value.items()))
            if key in conversion_lookup:
                return conversion_lookup[key](val)
        return value

    def convert_dynamodb_json_list(self, dynamodb_json_list: list[Any]) -> list:
        json_list: list = []
        for dynamodb_json in dynamodb_json_list:
            json_list.append(self.convert_dynamodb_json(dynamodb_json))
        return json_list


class CronScheduler:
    def __init__(self, cron_expression: str, start_time: Optional[datetime] = None, timezone: str = "UTC") -> None:
        self.cron_expression: str = cron_expression
        self.timezone: str = timezone
        self.start_time: datetime = self._convert_to_timezone(start_time) if start_time else self._convert_to_timezone(datetime.now())
        self.minute, self.hour, self.day_of_month, self.month, self.day_of_week = self.parse_cron(cron_expression)

    def _convert_to_timezone(self, dt: datetime) -> datetime:
        tz = pytz.timezone(self.timezone)
        return dt.astimezone(tz) if dt.tzinfo else tz.localize(dt)

    def parse_cron(self, cron_expression: str) -> Tuple[str, str, str, str, str]:
        """
        Parses a cron expression into its components.

        :param cron_expression: str, the cron expression
        :return: tuple, (minute, hour, day_of_month, month, day_of_week)
        """
        minute, hour, day_of_month, month, day_of_week = cron_expression.split()
        return minute, hour, day_of_month, month, day_of_week

    def match_minute(self, current_time: datetime) -> bool:
        return self.match_field(self.minute, current_time.minute)

    def match_hour(self, current_time: datetime) -> bool:
        return self.match_field(self.hour, current_time.hour)

    def match_day_of_month(self, current_time: datetime) -> bool:
        return self.match_field(self.day_of_month, current_time.day)

    def match_month(self, current_time: datetime) -> bool:
        return self.match_field(self.month, current_time.month)

    def match_day_of_week(self, current_time: datetime) -> bool:
        return self.match_field(self.day_of_week, current_time.weekday())

    def match_field(self, field: str, value: int) -> bool:
        """
        Matches a cron field to a specific value.

        :param field: str, the cron field (e.g., "5", "*", "1-5", "*/2", "1,3,5")
        :param value: int, the value to match against
        :return: bool, True if the field matches the value
        """
        if field == "*":
            return True
        if "*" in field:
            return True  # "*" matches anything
        if "," in field:
            values = [int(x) for x in field.split(",")]
            return value in values
        if "/" in field:
            base, step = map(int, field.split("/"))
            return (value - base) % step == 0
        if "-" in field:
            start, end = map(int, field.split("-"))
            return start <= value <= end
        return int(field) == value

    def next_scheduled_datetime(self) -> datetime:
        """
        Converts a cron expression to the next scheduled datetime.

        :return: datetime, the next scheduled datetime
        """
        current_time: datetime = self.start_time.replace(second=0, microsecond=0)

        while True:
            if self.is_match(current_time):
                return current_time
            current_time += timedelta(minutes=1)

    def is_match(self, current_time: datetime) -> bool:
        """
        Checks if the current time matches the cron expression.

        :param current_time: datetime, the current time
        :return: bool, True if the current time matches the cron expression
        """
        return (
            self.match_minute(current_time)
            and self.match_hour(current_time)
            and self.match_day_of_month(current_time)
            and self.match_month(current_time)
            and self.match_day_of_week(current_time)
        )

    def is_within_period(self, start_cron: str, end_cron: str, check_time: Optional[datetime] = None) -> bool:
        """
        Checks if the current time is within the start and end cron period.

        :param start_cron: str, the start cron expression
        :param end_cron: str, the end cron expression
        :param check_time: Optional[datetime], the time to check. Defaults to now.
        :return: bool, True if the check time is within the start and end period
        """
        check_time = check_time or datetime.now()

        start_scheduler = CronScheduler(start_cron, check_time)
        end_scheduler = CronScheduler(end_cron, check_time)

        start_time = start_scheduler.next_scheduled_datetime()
        end_time = end_scheduler.next_scheduled_datetime()

        if start_time <= check_time <= end_time:
            return True

        return False

    def is_close_to_current(self, n_minutes: int, check_time: Optional[datetime] = None) -> bool:
        """
        Checks if the cron expression is close to the current datetime (within n minutes).

        :param n_minutes: int, the maximum allowed difference in minutes
        :param check_time: Optional[datetime], the time to check. Defaults to now.
        :return: bool, True if the cron expression is close to the current datetime
        """
        check_time = check_time or datetime.now()
        check_time = self._convert_to_timezone(check_time)

        next_run_time = self.next_scheduled_datetime()
        next_run_time = self._convert_to_timezone(next_run_time)

        difference_minutes = (next_run_time - check_time).total_seconds() // 60

        return abs(difference_minutes) <= n_minutes


class EC2Manager:
    def __init__(self, region_name=get_region()) -> None:
        self.ec2 = boto3.client("ec2", region_name=region_name)

    def get_instance_states(self) -> dict | str:
        try:
            response = self.ec2.describe_instances()
            instance_states = {}
            for reservation in response["Reservations"]:
                for instance in reservation["Instances"]:
                    instance_id = instance["InstanceId"]
                    state = instance["State"]["Name"]
                    instance_states[instance_id] = state
            return instance_states
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"
        except Exception as e:
            return f"Error getting instance states: {e}"

    def get_stopped_instances(self) -> dict | str:
        try:
            response = self.ec2.describe_instances(
                Filters=[
                    {"Name": "instance-state-name", "Values": ["stopped"]},
                ]
            )
            instance_states = {}
            for reservation in response["Reservations"]:
                for instance in reservation["Instances"]:
                    instance_id = instance["InstanceId"]
                    state = instance["State"]["Name"]
                    instance_states[instance_id] = state
            return instance_states
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"
        except Exception as e:
            return f"Error getting instance states: {e}"

    def start_instances(self, instance_ids: list) -> dict | str:
        try:
            response: dict = self.ec2.start_instances(InstanceIds=instance_ids)
            return response
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"
        except Exception as e:
            return f"Error starting instances: {e}"


class ProcessAutoStarts:
    def __init__(self, region_name=get_region()) -> None:
        self.ec2_manager = EC2Manager()
        self.as_client = DynamoDBClient(get_ddbt_auto_start(), region_name)

    def go(self, now: datetime) -> None:
        stopped_instances = self.ec2_manager.get_stopped_instances()
        if isinstance(stopped_instances, str):
            sys.exit(stopped_instances)
        dd(stopped_instances)

        # get all the items from the auto_starts table
        auto_starts = self.as_client.scan()
        if isinstance(auto_starts, str): # quick check for errors
            sys.exit(auto_starts)
        auto_starts: list = self.as_client.convert_dynamodb_json_list(auto_starts)
        dd(auto_starts)
        start_instances =[]
        # loop auto_starts to get tz and crons
        for auto_start in auto_starts:
            instance_id: str = auto_start.get("instance_id")
            name: str = auto_start.get("name")
            timezone: str = auto_start.get("timezone")
            cron_expressions: list = auto_start.get("cron_expressions")
            # loop the crons to check if it's time to start the instance
            for cron_expression in cron_expressions:
                scheduler = CronScheduler(cron_expression, now, timezone)
                is_close: bool = scheduler.is_close_to_current(15)
                if is_close:
                    print(f"name: {name} cron:{cron_expression}")
                    start_instances.append(instance_id)
                    break
        dd(start_instances)
        for instance_id in start_instances:
            if instance_id in stopped_instances:
                # TODO
                print(f"I'm going to start: {instance_id}")


def lambda_handler(event, context) -> None:
    # get current datetime to compare cron expressions to
    now: datetime = datetime.now()
    print(now.__str__())
    now: datetime = round_dt(now)
    print(now.__str__())

    # === Auto Starts ===
    ProcessAutoStarts().go(now)


"""
    # get the auto_start client and all items from the table
    as_client = DynamoDBClient(get_ddbt_auto_start())
    as_items = as_client.convert_dynamodb_json_list(as_client.scan())
    dd(as_items)

    # === Maintenance Windows ===
    # get the maintenance_windows client and all items from the table
    mw_client = DynamoDBClient(get_ddbt_maintenance_windows())
    all_mw_items = mw_client.convert_dynamodb_json_list(mw_client.scan())
    dd(all_mw_items)

    

# Example usage
cron_expr = "*/15 * * * *"  # Every 15 minutes
scheduler = CronScheduler(cron_expr)
is_close = scheduler.is_close_to_current(30)  # Check if cron is close to current time within 30 minutes
print("Is cron close to current time:", is_close)


# Example usage
start_cron_expr = "0 18 * * *"  # Daily at 18:00
end_cron_expr = "0 20 * * *"  # Daily at 20:00

scheduler = CronScheduler(start_cron_expr)
is_within_period = scheduler.is_within_period(start_cron_expr, end_cron_expr)
print("Is current time within the period:", is_within_period)


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
