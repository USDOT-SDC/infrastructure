import boto3
import datetime
import os
from croniter import croniter
import pytz
import ctypes
import psutil
import time
import logging

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
    logging.info('shutting down')
    time.sleep(3)
    os.system('shutdown /s /t 1')

def script_running():
    processes = [
        p.cmdline() for p in psutil.process_iter() 
        if (p.name().lower() in ['python.exe'] and 'auto-stop.py' not in p.cmdline()[1])
        or (p.name().lower() in ['r', 'rscript'])
    ]    
    
    if len(processes) > 0:
        logging.info('a script is running on the computer')

    return len(processes)

def get_idle_time():
    if os.name == 'nt':  # Windows
        from ctypes import Structure, windll, c_uint, sizeof, byref
        
        class LASTINPUTINFO(Structure):
            _fields_ = [("cbSize", c_uint), ("dwTime", c_uint)]

        lii = LASTINPUTINFO()
        lii.cbSize = sizeof(LASTINPUTINFO)
        windll.user32.GetLastInputInfo(byref(lii))
        millis = windll.kernel32.GetTickCount() - lii.dwTime
        return millis / 1000.0  # Convert to seconds
    else:
        raise NotImplementedError("Idle time detection is not implemented for this OS")

# Function to track idle time
def track_idle_time():
    idle_threshold = 3600  # 1 hour in seconds
    idle_time = get_idle_time()

    # Check if idle time is greater than or equal to the threshold
    if idle_time >= idle_threshold:
        logging.info("Computer has been idle for 1 hour.")
        return True
    else:
        logging.info(f"Idle time: {idle_time/60:.2f} minutes")
        return False

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    log_file = os.path.join(script_dir, 'auto-stop-logs.log')
    logging.basicConfig(
    filename=log_file,
    level=logging.INFO,  # Set the logging level
    format='%(asctime)s - %(levelname)s - %(message)s'
    )
    logging.info('auto-stop.py called by scheduled task')
    maintenance_windows = get_maintenance_windows()
    within_window = False
    for cron_expression, duration, timezone in maintenance_windows:
        if is_within_maintenance_window(cron_expression, duration, timezone):
            within_window = True
            logging.info('within maintenance window')
            break
    script_running = script_running()
    if within_window or not script_running == 0 and not track_idle_time():
        print("Within maintenance window. No action taken.")
    else:
        print("Not within maintenance window. Shutting down the computer.")
        shutdown_computer()
