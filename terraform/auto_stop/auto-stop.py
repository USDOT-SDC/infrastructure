import boto3
import datetime
import os
from croniter import croniter
import pytz
import ctypes

# Set region
boto3.setup_default_session(region_name='us-east-1')

# Define the DynamoDB table name
TABLE_NAME = 'instance_maintenance_windows'

# Initialize a session using Amazon DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

def get_maintenance_windows() -> list:
    """
    Retrieves maintenance windows from DynamoDB table.

    Returns:
        list: A list of tuples, each containing (cron_expression, duration, timezone).
              Example: [('0 0 * * *', '01:00', 'America/New_York')]
    """
    maintenance_windows = []
    try:
        response = table.scan()
        for item in response.get('Items', []):
            cron_expression = item['cron_expression']
            duration = item['duration']
            timezone = item['timezone']
            maintenance_windows.append((cron_expression, duration, timezone))
    except Exception as e:
        print(f"Error fetching maintenance windows: {e}")
    return maintenance_windows

def parse_duration(duration_str: str) -> datetime.timedelta:
    """
    Parses duration string in 'HH:MM' format into a timedelta object.

    Args:
        duration_str (str): Duration string in 'HH:MM' format.

    Returns:
        datetime.timedelta: Timedelta object representing the parsed duration.
    """
    hours, minutes = map(int, duration_str.split(':'))
    return datetime.timedelta(hours=hours, minutes=minutes)

def is_within_maintenance_window(cron_expression: str, duration: str, timezone: str) -> bool:
    """
    Checks if the current time is within a maintenance window defined by cron expression, duration, and timezone.

    Args:
        cron_expression (str): Cron expression defining the schedule of the maintenance window.
        duration (str): Duration of the maintenance window in 'HH:MM' format.
        timezone (str): Timezone name (e.g., 'America/New_York').

    Returns:
        bool: True if current time is within the maintenance window, False otherwise.
    """
    tz = pytz.timezone(timezone)
    current_time = datetime.datetime.now(tz)
    print(f"Current time: {current_time}")

    start_iter = croniter(cron_expression, current_time)
    last_start = start_iter.get_prev(datetime.datetime)
    end_time = last_start + parse_duration(duration)
    
    print(f"Last start time: {last_start}")
    print(f"End time: {end_time}")

    return last_start <= current_time <= end_time

def shutdown_computer():
    """
    Shuts down the computer.
    """
    print("SHUTTING DOWN")
    os.system('shutdown /s /t 1')

if __name__ == "__main__":
    maintenance_windows = get_maintenance_windows()
    within_window = False
    for cron_expression, duration, timezone in maintenance_windows:
        if is_within_maintenance_window(cron_expression, duration, timezone):
            within_window = True
            break
    
    if within_window:
        print("Within maintenance window. No action taken.")
    else:
        print("Not within maintenance window. Shutting down the computer.")
        shutdown_computer()
