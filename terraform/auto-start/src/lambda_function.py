import sys
sys.path.append("./site-packages")
import json
import os
import pytz
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError
from boto3.resources.base import ServiceResource
from croniter import croniter  # type: ignore
from datetime import datetime, timedelta, timezone
from typing import Any, List, Union, Dict, Callable, Optional


def get_env() -> str:
    """
    gets ENV from sys environment vars

    Returns:
        str: the env (dev, test, stage, prod)
    """
    return os.getenv("ENV", "dev")


def get_region() -> str:
    """
    gets REGION from sys environment vars

    Returns:
        str: the AWS region (for now, it's always us-east-1)
    """
    return os.getenv("REGION", "us-east-1")


def get_ddbt_auto_starts() -> str:
    """
    gets DDBT_AUTO_START from sys environment vars

    Returns:
        str: the auto-start DynamoDB table name
    """
    return os.getenv("DDBT_AUTO_STARTS", "instance_auto_starts")


def get_ddbt_maintenance_windows() -> str:
    """
    gets DDBT_MAINTENANCE_WINDOW from sys environment vars

    Returns:
        str: the maintenance windows DynamoDB table name
    """
    return os.getenv("DDBT_MAINTENANCE_WINDOWS", "instance_maintenance_windows")


def round_dt(dt: datetime, minutes: int = 15) -> datetime:
    """
    rounds a datetime to the nearest n-minutes

    Args:
        dt (datetime): a datetime to be rounded
        minutes (int, optional): round the dt to the nearest of this. Defaults to 15.

    Returns:
        datetime: the rounded datetime
    """
    delta = timedelta(minutes=minutes)

    # Check if dt is aware or naive
    if dt.tzinfo is not None and dt.tzinfo.utcoffset(dt) is not None:
        # Offset-aware datetime
        epoch = datetime(1970, 1, 1, tzinfo=dt.tzinfo)
    else:
        # Offset-naive datetime
        epoch: datetime = datetime.min

    return epoch + (round((dt - epoch) / delta) * delta)


def dd(obj: Any) -> None:
    """
    used for debugging, prints objects so they can be inspected

    Args:
        obj (Any): the object to print
    """
    print(json.dumps(obj, indent=4, default=str()))


class DynamoDBClient:
    """
    Client for connecting to DynamoDB tables.
    """

    def __init__(self, table_name: str, region_name: str = get_region()) -> None:
        """
        Initializes the DynamoDBClient.

        Args:
            table_name (str): The DynamoDB table to connect to.
            region_name (str, optional): The AWS region. Defaults to get_region("us-east-1").
        """
        self.table_name: str = table_name
        self.dynamodb: ServiceResource = boto3.resource("dynamodb", region_name=region_name)
        self.table = self.dynamodb.Table(table_name)
        self.client = boto3.client("dynamodb", region_name=region_name)

    def add_item(self, item: dict) -> dict:
        """
        Adds an item to the DynamoDB table.

        Args:
            item (dict): The item to add.

        Returns:
            dict: The response from DynamoDB.
        """
        try:
            response = self.table.put_item(Item=item)
            return response
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def get_item(self, key: dict) -> Union[dict, None]:
        """
        Retrieves an item from the DynamoDB table based on the key.

        Args:
            key (dict): The key to retrieve the item.

        Returns:
            Union[dict, None]: The retrieved item or None if not found.
        """
        try:
            response = self.table.get_item(Key=key)
            return response.get("Item", None)
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def update_item(self, key: dict, update_expression: str, expression_attribute_values: dict) -> dict:
        """
        Updates an item in the DynamoDB table.

        Args:
            key (dict): The key to identify the item to update.
            update_expression (str): The update expression for modifying attributes.
            expression_attribute_values (dict): Values to substitute in the update expression.

        Returns:
            dict: The response from DynamoDB.
        """
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

    def delete_item(self, key: dict) -> dict:
        """
        Deletes an item from the DynamoDB table.

        Args:
            key (dict): The key to identify the item to delete.

        Returns:
            dict: The response from DynamoDB.
        """
        try:
            response = self.table.delete_item(Key=key)
            return response
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"

    def query(self, key_condition_expression: str, expression_attribute_values: dict) -> Union[list, str]:
        """
        Queries items in the DynamoDB table based on a key condition expression.

        Args:
            key_condition_expression (str): The key condition expression.
            expression_attribute_values (dict): Values to substitute in the key condition expression.

        Returns:
            Union[list, str]: List of items or an error message.
        """
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

    def scan(self, filter_expression: Optional[str] = None, expression_attribute_values: Optional[dict] = None) -> Union[list, str]:
        """
        Scans items in the DynamoDB table based on an optional filter expression.

        Args:
            filter_expression (str, optional): The filter expression. Defaults to None.
            expression_attribute_values (dict, optional): Values to substitute in the filter expression. Defaults to None.

        Returns:
            Union[list, str]: List of items or an error message.
        """
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

    def convert_dynamodb_json_list(self, dynamodb_json_list: List[Any]) -> List:
        """
        Converts a list of complex DynamoDB JSON into a list of standard typed JSON.

        Args:
            dynamodb_json_list (List[Any]): List of complex DynamoDB JSON.

        Returns:
            List: List of standard typed JSON.
        """
        json_list: List = []
        for dynamodb_json in dynamodb_json_list:
            json_list.append(self.convert_dynamodb_json(dynamodb_json))
        return json_list

    def convert_dynamodb_json(self, dynamodb_json: Dict[str, Any]) -> Dict:
        """
        Converts a complex DynamoDB JSON into a standard typed JSON.

        Args:
            dynamodb_json (Dict[str, Any]): Complex DynamoDB JSON.

        Returns:
            Dict: Standard typed JSON.
        """
        if isinstance(dynamodb_json, dict):
            return {k: self.convert_value(v) for k, v in dynamodb_json.items()}
        elif isinstance(dynamodb_json, list):
            return [self.convert_value(i) for i in dynamodb_json]
        else:
            return dynamodb_json

    def convert_value(self, value: Union[Any, Dict[str, Any]]) -> Union[Any, Dict]:
        """
        Converts DynamoDB data types to Python data types.

        Args:
            value (Union[Any, Dict[str, Any]]): DynamoDB typed data.

        Returns:
            Union[Any, Dict]: Python typed data.
        """
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


class CronScheduler:
    """
    Parses cron expressions and evaluates them against a check datetime.
    """

    def __init__(self, cron_expression: str, check_time: Optional[datetime] = None) -> None:
        """
        Initializes the CronScheduler.

        Args:
            cron_expression (str): A cron expression.
            check_time (Optional[datetime], optional): The check datetime. Defaults to None.
        """
        self.cron_expression: str = cron_expression
        self.check_time: datetime = check_time if check_time else datetime.now(tz=timezone.utc)

    def is_close_to_current(self, n_minutes: int = 14) -> bool:
        """
        Checks if the cron expression is close to the current datetime (within n minutes).

        Args:
            n_minutes (int): The maximum allowed difference in minutes.

        Returns:
            bool: True if the cron expression is close to the current datetime.
        """
        next_run_time = croniter(self.cron_expression, self.check_time).get_next(datetime)
        difference_minutes = (next_run_time - self.check_time).total_seconds() // 60
        return abs(difference_minutes) <= n_minutes

    def is_within_period(self, duration: str) -> bool:
        """
        Checks if the check_time is within the period defined by cron_expression and duration.

        Args:
            duration (str): The duration in HH:mm format.

        Returns:
            bool: True if the check time is within the period.
        """
        iter = croniter(self.cron_expression, self.check_time)
        last_run_time = iter.get_prev(datetime)

        duration_hours, duration_minutes = map(int, duration.split(":"))
        period_duration = timedelta(hours=duration_hours, minutes=duration_minutes)
        end_time = last_run_time + period_duration
        is_active: bool = last_run_time <= self.check_time <= end_time

        return is_active


class EC2Manager:
    """
    Manager for EC2 instances, handles getting instance states and starting instances.
    """

    def __init__(self, region_name: str = get_region()) -> None:
        """
        Initializes the EC2Manager.

        Args:
            region_name (str, optional): The AWS region name. Defaults to the value obtained from get_region().
        """
        self.ec2 = boto3.client("ec2", region_name=region_name)

    def get_instance_states(self) -> dict[str, str] | str:
        """
        Retrieves the states of all instances.

        Returns:
            dict[str, str] | str: A dictionary mapping instance IDs to their states, or an error message.
        """
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

    def get_stopped_instances(self) -> dict[str, str] | str:
        """
        Retrieves the states of stopped instances.

        Returns:
            dict[str, str] | str: A dictionary mapping instance IDs to their states, or an error message.
        """
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
            if not bool(instance_states):
                print("EC2Manager.get_stopped_instances() -> instance_states is Empty (there are no stopped instances)")
            return instance_states
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"
        except Exception as e:
            return f"Error getting instance states: {e}"

    def start_instances(self, instance_ids: list[str]) -> list[dict[str, str]] | str:
        """
        Starts instances specified by their IDs.

        Args:
            instance_ids (list[str]): A list of instance IDs to be started.

        Returns:
            list[dict[str, str]] | str: A list of dictionaries with instance ID and current state, or an error message.
        """
        try:
            response: dict = self.ec2.start_instances(InstanceIds=instance_ids)
            starting_instances: list[dict[str, str]] = []
            for starting_instance in response.get("StartingInstances"):
                instance_id = starting_instance.get("InstanceId")
                current_state = starting_instance.get("CurrentState").get("Name")
                starting_instances.append({"instance_id": instance_id, "current_state": current_state})
            return starting_instances
        except (NoCredentialsError, PartialCredentialsError) as e:
            return f"Credentials error: {e}"
        except Exception as e:
            return f"Error starting instances: {e}"


class ProcessAutoStarts:
    """
    Processor for managing auto-start of instances.
    """

    def __init__(self, now_utc: Optional[datetime] = None, region_name=get_region()) -> None:
        """
        Initializes the ProcessAutoStarts class.

        Args:
            now_utc (Optional[datetime], optional): UTC datetime, serves as point in time to check schedule against. Defaults to None.
            region_name (str, optional): AWS region. Defaults to the result of get_region().
        """
        self.ec2_manager = EC2Manager()
        self.as_client = DynamoDBClient(get_ddbt_auto_starts(), region_name)
        self.now_utc: datetime = now_utc if now_utc else datetime.now(tz=timezone.utc)

    def get_start_instances(self, auto_starts: list) -> list:
        """
        Determines which instances should be started based on their cron expressions.

        Args:
            auto_starts (list): List of items from the DynamoDB auto-starts table.

        Returns:
            list: List of instances that should be started.
        """
        start_instances = []
        for auto_start in auto_starts:
            instance_id = auto_start.get("instance_id")
            cron_timezone = pytz.timezone(auto_start.get("timezone", "UTC"))
            check_time = self.now_utc.astimezone(cron_timezone)
            cron_expressions = auto_start.get("cron_expressions", [])
            if self.should_start_instance(cron_expressions, check_time):
                start_instances.append(instance_id)
        if not start_instances:
            print("ProcessAutoStarts.get_start_instances() -> start_instances is Empty (no instances with cron close to check_time)")
        return start_instances

    def should_start_instance(self, cron_expressions: list, check_time: datetime) -> bool:
        """
        Checks if an instance should be started based on cron expressions.

        Args:
            cron_expressions (list): List of cron expressions.
            check_time (datetime): The time to check against the cron expressions.

        Returns:
            bool: True if the instance should be started, False otherwise.
        """
        for cron_expression in cron_expressions:
            scheduler = CronScheduler(cron_expression, check_time)
            if scheduler.is_close_to_current(14):
                return True
        return False

    def go(self) -> None:
        """
        Orchestrates the auto-start process.

        Retrieves stopped instances, checks auto-start configurations,
        and attempts to start instances if their schedule matches the current time.
        """
        stopped_instances = self.get_stopped_instances()
        auto_starts = self.get_auto_starts()
        start_instances = self.get_start_instances(auto_starts)
        self.process_start_instances(start_instances, stopped_instances)

    def get_stopped_instances(self) -> dict:
        """
        Retrieves the list of stopped EC2 instances.

        Returns:
            dict: Dictionary of stopped instance IDs and their states.

        Exits if an error is encountered.
        """
        stopped_instances = self.ec2_manager.get_stopped_instances()
        self.exit_if_error(stopped_instances)
        return stopped_instances

    def get_auto_starts(self) -> list:
        """
        Retrieves the auto-start configurations from DynamoDB.

        Returns:
            list: List of auto-start configurations.

        Exits if an error is encountered.
        """
        auto_starts = self.as_client.scan()
        self.exit_if_error(auto_starts)
        return self.as_client.convert_dynamodb_json_list(auto_starts)

    def exit_if_error(self, result: any) -> None:
        """
        Exits the program if the result is an error message.

        Args:
            result (any): The result to check for errors.

        Exits:
            If the result is a string (error message), the program exits.
        """
        if isinstance(result, str):
            sys.exit(result)

    def process_start_instances(self, start_instances: list, stopped_instances: dict) -> None:
        """
        Processes start instances and attempts to start them if they are stopped.

        Args:
            start_instances (list): List of instances that should be started.
            stopped_instances (dict): Dictionary of stopped instance IDs and their states.
        """
        for instance_id in start_instances:
            if instance_id in stopped_instances:
                self.log_attempt(instance_id)
                starting_instances = self.ec2_manager.start_instances([instance_id])
                self.exit_if_error(starting_instances)
                self.log_starting_instances(starting_instances)
            else:
                self.log_non_stopped_instance(instance_id)

    def log_attempt(self, instance_id: str) -> None:
        """
        Logs the attempt to start an instance.

        Args:
            instance_id (str): The ID of the instance being attempted to start.
        """
        print(f"ProcessAutoStarts.go() # Attempting to start: {instance_id} CurrentState:stopped")

    def log_non_stopped_instance(self, instance_id: str) -> None:
        """
        Logs an instance that is scheduled to start but is not currently stopped.

        Args:
            instance_id (str): The ID of the instance.
        """
        print(f"ProcessAutoStarts.go() # Schedule to start, but did not attempt: {instance_id} CurrentState:other-than-stopped")

    def log_starting_instances(self, starting_instances: list) -> None:
        """
        Logs the result of starting instances.

        Args:
            starting_instances (list): List of starting instances with their states.
        """
        for starting_instance in starting_instances:
            instance_id = starting_instance.get("instance_id")
            current_state = starting_instance.get("current_state")
            print(f"ProcessAutoStarts.go() #  Attempted to start: {instance_id} CurrentState:{current_state}")


class ProcessMaintenanceWindows:
    """
    Processor for managing maintenance windows.
    """

    def __init__(self, now_utc: Optional[datetime] = None, region_name=get_region()) -> None:
        """
        Initializes the ProcessMaintenanceWindows class.

        Args:
            now_utc (Optional[datetime], optional): UTC datetime, serves as point in time to check schedule against. Defaults to None.
            region_name (str, optional): AWS region. Defaults to the result of get_region().
        """
        self.ec2_manager = EC2Manager()
        self.mw_client = DynamoDBClient(get_ddbt_maintenance_windows(), region_name)
        self.now_utc: datetime = now_utc if now_utc else datetime.now(tz=timezone.utc)

    def maintenance_window_is_active(self, maintenance_windows: list) -> list[dict[str, str | bool]]:
        """
        Determines if maintenance windows are active based on their cron expressions and durations.

        Args:
            maintenance_windows (list): List of maintenance window configurations.

        Returns:
            list[dict[str, str | bool]]: List of maintenance windows with their active status.
        """
        result: list = []
        for maintenance_window in maintenance_windows:
            maintenance_window_id = maintenance_window.get("maintenance_window_id", "Not Found")
            cron_timezone: datetime.tzinfo = pytz.timezone(maintenance_window.get("timezone", "UTC"))
            check_time = self.now_utc.astimezone(cron_timezone)
            cron_expression = maintenance_window.get("cron_expression")
            duration = maintenance_window.get("duration")
            scheduler = CronScheduler(cron_expression, check_time)
            if scheduler.is_within_period(duration):
                result.append({"id": maintenance_window_id, "active": True})
            else:
                result.append({"id": maintenance_window_id, "active": False})
        return result

    def go(self) -> None:
        """
        Orchestrates the maintenance window process.

        Retrieves stopped instances, checks maintenance window status,
        and attempts to start instances if within an active maintenance window.
        """
        stopped_instances = self.get_stopped_instances()
        maintenance_windows = self.get_maintenance_windows()
        active_windows = self.maintenance_window_is_active(maintenance_windows)
        self.process_maintenance_windows(active_windows, stopped_instances)

    def get_stopped_instances(self) -> dict:
        """
        Retrieves the list of stopped EC2 instances.

        Returns:
            dict: Dictionary of stopped instance IDs and their states.

        Exits if an error is encountered.
        """
        stopped_instances = self.ec2_manager.get_stopped_instances()
        self.exit_if_error(stopped_instances)
        return stopped_instances

    def get_maintenance_windows(self) -> list:
        """
        Retrieves the maintenance window configurations from DynamoDB.

        Returns:
            list: List of maintenance window configurations.

        Exits if an error is encountered.
        """
        maintenance_windows = self.mw_client.scan()
        self.exit_if_error(maintenance_windows)
        return self.mw_client.convert_dynamodb_json_list(maintenance_windows)

    def exit_if_error(self, result: any) -> None:
        """
        Exits the program if the result is an error message.

        Args:
            result (any): The result to check for errors.

        Exits:
            If the result is a string (error message), the program exits.
        """
        if isinstance(result, str):
            sys.exit(result)

    def process_maintenance_windows(self, maintenance_windows: list[dict[str, str | bool]], stopped_instances: dict) -> None:
        """
        Processes maintenance windows and starts instances if they are within active windows.

        Args:
            maintenance_windows (list[dict[str, str | bool]]): List of maintenance windows with their active status.
            stopped_instances (dict): Dictionary of stopped instance IDs and their states.
        """
        for maintenance_window in maintenance_windows:
            mw_id: str = maintenance_window.get("id")
            if maintenance_window.get("active"):
                self.log_active_window(mw_id)
                self.start_instances_in_window(stopped_instances)
            else:
                self.log_inactive_window(mw_id)

    def log_active_window(self, mw_id: str) -> None:
        """
        Logs an active maintenance window.

        Args:
            mw_id (str): The ID of the active maintenance window.
        """
        print(f"ProcessMaintenanceWindows.go() # Maintenance Window: {mw_id}, is active")

    def log_inactive_window(self, mw_id: str) -> None:
        """
        Logs an inactive maintenance window.

        Args:
            mw_id (str): The ID of the inactive maintenance window.
        """
        print(f"ProcessMaintenanceWindows.go() # Maintenance Window: {mw_id}, is inactive")

    def start_instances_in_window(self, stopped_instances: dict) -> None:
        """
        Attempts to start instances within an active maintenance window.

        Args:
            stopped_instances (dict): Dictionary of stopped instance IDs and their states.
        """
        for instance_id in stopped_instances.keys():
            self.log_attempt(instance_id)
            starting_instances = self.ec2_manager.start_instances([instance_id])
            self.exit_if_error(starting_instances)
            self.log_starting_instances(starting_instances)

    def log_attempt(self, instance_id: str) -> None:
        """
        Logs the attempt to start an instance.

        Args:
            instance_id (str): The ID of the instance being attempted to start.
        """
        print(f"ProcessMaintenanceWindows.go() # Attempting to start:{instance_id} CurrentState:stopped")

    def log_starting_instances(self, starting_instances: list) -> None:
        """
        Logs the result of starting instances.

        Args:
            starting_instances (list): List of starting instances with their states.
        """
        for starting_instance in starting_instances:
            instance_id = starting_instance.get("instance_id")
            current_state = starting_instance.get("current_state")
            print(f"ProcessMaintenanceWindows.go() #  Attempted to start: {instance_id} CurrentState:{current_state}")


def lambda_handler(event, context) -> None:
    """
    The AWS Lambda handler

    Args:
        event (_type_): CloudWatch event
        context (_type_): Lambda invoke context
    """
    # rounding minutes
    round_minutes = 15
    # get current UTC datetime to compare cron expressions to and round it to nearest round_minutes
    now_utc: datetime = round_dt(datetime.now(tz=timezone.utc), minutes=round_minutes)
    # log rounded now_utc
    print(f"round_dt(now_utc, minutes={round_minutes}): {now_utc.__str__()}")
    # get current rounded EST
    est_timezone: pytz.timezone = pytz.timezone("EST")
    now_est: datetime = now_utc.astimezone(est_timezone)
    # log rounded now_est
    print(f"round_dt(now_est, minutes={round_minutes}): {now_est.__str__()}")

    # === Auto Starts ===
    ProcessAutoStarts(now_utc).go()

    # === Maintenance Windows ===
    ProcessMaintenanceWindows(now_utc).go()
