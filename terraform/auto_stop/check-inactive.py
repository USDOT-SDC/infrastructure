import boto3
import datetime
import os
from croniter import croniter
import pytz
import ctypes

# Define the DynamoDB table name
TABLE_NAME = 'instance_maintenance_windows'

# Initialize a session using Amazon DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

def get_maintenance_windows():
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

def parse_duration(duration_str):
    hours, minutes = map(int, duration_str.split(':'))
    return datetime.timedelta(hours=hours, minutes=minutes)

def is_within_maintenance_window(cron_expression, duration, timezone):
    tz = pytz.timezone(timezone)
    current_time = datetime.datetime.now(tz)
    print(f"Current time: {current_time}")

    start_iter = croniter(cron_expression, current_time)
    last_start = start_iter.get_prev(datetime.datetime)
    end_time = last_start + parse_duration(duration)
    
    print(f"Last start time: {last_start}")
    print(f"End time: {end_time}")

    return last_start <= current_time <= end_time

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def shutdown_computer():
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
