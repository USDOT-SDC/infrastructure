import boto3
import yaml
import datetime as dt
from datetime import time, timezone, timedelta
import calendar
import pytz

# from pathlib import Path


days_of_week = [
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
]
region_name = "us-east-1"
instance_stop_tag_key = "InstanceScheduler:StopDatetime"
current_utc_datetime = dt.datetime.now(timezone.utc)
print("current_utc_datetime: " + str(current_utc_datetime))
print("")


def get_env():
    ssm = boto3.client("ssm", region_name=region_name)
    ssm_parameter = ssm.get_parameter(Name="environment", WithDecryption=False)
    return ssm_parameter["Parameter"]["Value"]


def get_global_schedule():
    global_schedule = []
    ssm = boto3.client("ssm", region_name=region_name)
    ec2 = boto3.client("ec2", region_name=region_name)
    # get the global schedule from parameter store
    ssm_parameter = ssm.get_parameter(Name="/Instance-Scheduler/Global-Schedule", WithDecryption=False)
    yaml_sch = yaml.safe_load(ssm_parameter["Parameter"]["Value"])
    if "Timezone" in yaml_sch and "Tags" in yaml_sch:
        tz = yaml_sch["Timezone"]
        gs_tags = yaml_sch["Tags"]
    else:
        print("Timezone and/or Tags are not specified")

    # Process the global schedule tags
    for gs_tag_key, gs_tag_schedules in gs_tags.items():
        # for each of the tag keys (Project, Team, Role, etc.)
        # and schedule (tag's value and list of schedules)
        instance_name = ""
        instance_stop_datetime = None
        gs_tag_key = str(gs_tag_key)
        for gs_tag_value, gs_schedules in gs_tag_schedules.items():
            # for each of the tag's values (Project-1, Team-B, Workstation)
            # and schedules (Day, Time, Duration)
            gs_tag_value = str(gs_tag_value)
            print("Global Schedule for: Tag:" + gs_tag_key + " Value:" + gs_tag_value)
            # get the instances with tag key:value
            response = ec2.describe_instances(
                Filters=[
                    {
                        "Name": "tag:" + gs_tag_key,
                        "Values": [gs_tag_value],
                    },
                ]
            )
            for reservation in response["Reservations"]:
                for instance in reservation["Instances"]:
                    # for each instance in the response
                    instance_id = instance["InstanceId"]
                    instance_state = instance["State"]["Name"]
                    instance_tags = instance["Tags"]
                    for instance_tag in instance_tags:
                        # loop the tags to find Name and StopDatetime
                        if instance_tag["Key"] == "Name":
                            instance_name = instance_tag["Value"]
                        elif instance_tag["Key"] == instance_stop_tag_key:
                            instance_stop_datetime = instance_tag["Value"]
                    print("Workstation:" + instance_name + " " + instance_id)
                    for gs_sch in gs_schedules:
                        # loop each schedule to get all values to append to global_schedule
                        gs_sch_day = str(gs_sch["Day"])
                        gs_sch_time = str(gs_sch["Time"])
                        gs_sch_duration = str(gs_sch["Duration"])
                        global_schedule.append(
                            {
                                "Type": "global",
                                "InstanceId": instance_id,
                                "InstanceState": instance_state,
                                "InstanceStopDatetime": instance_stop_datetime,
                                "Workstation": instance_name,
                                "Timezone": tz,
                                "Day": gs_sch_day,
                                "Time": gs_sch_time,
                                "Duration": gs_sch_duration,
                            }
                        )
    return global_schedule


def get_team_schedules():
    team_schedules = []
    instance_stop_datetime = None
    s3 = boto3.resource("s3")
    ec2 = boto3.client("ec2", region_name=region_name)
    for bucket in s3.buckets.all():
        # loop all the buckets
        if bucket.name.startswith(get_env() + ".sdc.dot.gov.team"):
            # is a team bucket
            for o in bucket.objects.filter(Prefix="Workstation-Schedules/"):
                # loop all the objects in the Workstation-Schedules prefix
                if o.key.endswith(".yaml") or o.key.endswith(".yml"):
                    # is a yaml file
                    yaml_sch = yaml.safe_load(o.get()["Body"].read())
                    if "Workstation" in yaml_sch and "Timezone" in yaml_sch and "Schedules" in yaml_sch:
                        # has the data expected
                        wkst = yaml_sch["Workstation"]
                        wkst_tz = yaml_sch["Timezone"]
                        wkst_schedules = yaml_sch["Schedules"]
                    else:
                        print("Workstation, Timezone and/or Schedules are not specified")
                        continue
                    print("Team Schedule for: Bucket:" + bucket.name + " Object:" + o.key)
                    # get the instances with tag Name:value
                    response = ec2.describe_instances(
                        Filters=[
                            {
                                "Name": "tag:Name",
                                "Values": [wkst],
                            },
                        ]
                    )
                    # Assumes only one instance w/given Name
                    instance = response["Reservations"][0]["Instances"][0]
                    instance_id = instance["InstanceId"]
                    instance_state = instance["State"]["Name"]
                    for instance_tag in instance["Tags"]:
                        # loop the tags to find StopDatetime
                        if instance_tag["Key"] == instance_stop_tag_key:
                            instance_stop_datetime = instance_tag["Value"]
                    print("Workstation:" + wkst + " " + instance_id)
                    for wkst_sch in wkst_schedules:
                        # loop each schedule to get all values to append to team_schedules
                        team_schedules.append(
                            {
                                "Type": "team",
                                "InstanceId": instance_id,
                                "InstanceState": instance_state,
                                "InstanceStopDatetime": instance_stop_datetime,
                                "Workstation": wkst,
                                "Timezone": wkst_tz,
                                "Day": wkst_sch["Day"],
                                "Time": wkst_sch["Time"],
                                "Duration": wkst_sch["Duration"],
                            }
                        )
    return team_schedules


def stop_instances_with_stop_datetime():
    ec2 = boto3.client("ec2", region_name=region_name)
    instances_to_stop = []
    # get the instances with a tag InstanceScheduler:StopDatetime
    response = ec2.describe_instances(
        Filters=[
            {
                "Name": "tag-key",
                "Values": [instance_stop_tag_key],
            }
        ]
    )
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            # loop the instances to get some values
            instance_id = instance["InstanceId"]
            instance_state = instance["State"]["Name"]
            instance_tags = instance["Tags"]
            for instance_tag in instance_tags:
                # loop the tags to find Name and StopDatetime
                if instance_tag["Key"] == "Name":
                    instance_name = instance_tag["Value"]
                elif instance_tag["Key"] == instance_stop_tag_key:
                    instance_stop_datetime = instance_tag["Value"]
            # append to instances_to_stop
            instances_to_stop.append(
                {
                    "InstanceId": instance_id,
                    "InstanceName": instance_name,
                    "InstanceState": instance_state,
                    "InstanceStopDatetime": instance_stop_datetime,
                }
            )
    for instance_to_stop in instances_to_stop:
        # loop each instance to get it's InstanceStopDatetime value
        i_stop_datetime = dt.datetime.fromisoformat(instance_to_stop["InstanceStopDatetime"])
        if i_stop_datetime < current_utc_datetime + timedelta(minutes=8):
            # InstanceStopDatetime is less than current_utc_datetime + 8 minutes
            # Is in the past or about to be in the past
            print("Stopping Workstation:" + instance_to_stop["InstanceName"] + " " + instance_to_stop["InstanceId"])
            stop_instance(instance_to_stop["InstanceId"])
            delete_stop_datetime(instance_to_stop["InstanceId"])


def get_hm_from_str(time_):
    # time as string, HH:MM
    hr = int(time_.split(":")[0])
    mn = int(time_.split(":")[1])
    return [hr, mn]


def get_datetime_from_time_and_timezone(time_, timezone_):
    # time as string, HH:MM
    # timezone as string, US/Eastern US/Mountain
    tz = pytz.timezone(timezone_)
    dat = dt.datetime.now(tz).date()
    time_list = get_hm_from_str(time_)
    tm = time(time_list[0], time_list[1])
    return tz.localize(dt.datetime.combine(dat, tm))


def is_time_to_do_it(sch_current_datetime, sch_datetime):
    # compare 2 datetimes to see if they are appropriately the same
    min_datetime = sch_current_datetime - timedelta(minutes=8)
    max_datetime = sch_current_datetime + timedelta(minutes=8)
    if min_datetime <= sch_datetime <= max_datetime:
        return True
    else:
        return False


def is_day_to_run(sch_current_datetime, sch_day):
    # is the current datetime the day to run
    if isinstance(sch_day, str):
        # is a string
        if sch_day.lower() == "daily":
            # is daily
            return True
        elif sch_day.lower() in days_of_week:
            # is a day of the week
            if sch_day.lower() == sch_current_datetime.strftime("%A").lower():
                # is today's day of the week
                return True
            else:
                return False
        else:
            print("Unknown string")
            return False
    elif isinstance(sch_day, int):
        # is an integer
        if 1 <= sch_day <= 31 or sch_day == -1:
            # is a day of the month
            y = sch_current_datetime.year
            m = sch_current_datetime.month
            d = sch_current_datetime.day
            if d == calendar.monthrange(y, m)[1] and sch_day == -1:
                # is last day of the month
                return True
            elif d == sch_day:
                # is today's day of the month
                return True
            else:
                return False
        else:
            print("Day of month, out of range")
            return False
    elif isinstance(sch_day, dt.date):
        # is a datetime
        if sch_day == sch_current_datetime.date():
            # is today's date
            return True
        else:
            return False
    else:
        print("Unknown data type")
        return False


def start_instance(iid):
    ec2 = boto3.client("ec2", region_name=region_name)
    ec2.start_instances(InstanceIds=[iid])


def stop_instance(iid):
    ec2 = boto3.client("ec2", region_name=region_name)
    ec2.stop_instances(InstanceIds=[iid])


def get_datetime_from_duration(duration):
    # duration is a string in form HH:MM
    duration_ints = get_hm_from_str(duration)
    return current_utc_datetime + timedelta(hours=duration_ints[0], minutes=duration_ints[1])


def set_stop_datetime(iid, stop_datetime):
    # sets the InstanceScheduler:StopDatetime tag
    ec2 = boto3.client("ec2", region_name=region_name)
    response = ec2.create_tags(
        Resources=[iid],
        Tags=[
            {
                "Key": instance_stop_tag_key,
                "Value": stop_datetime.isoformat(timespec="minutes"),
            },
        ],
    )


def delete_stop_datetime(iid):
    # deletes the InstanceScheduler:StopDatetime tag
    ec2 = boto3.client("ec2", region_name=region_name)
    response = ec2.delete_tags(Resources=[iid], Tags=[{"Key": instance_stop_tag_key}])


def lambda_handler(event, context):
    schedules = []

    # for prod
    print("Getting global schedule...")
    global_schedule = get_global_schedule()
    schedules.extend(global_schedule)
    print("Getting global schedule...Done")
    print("")

    print("Getting team schedules...")
    team_schedules = get_team_schedules()
    schedules.extend(team_schedules)
    print("Getting team schedules...")
    print("")

    # for development (getting yamls from team buckets is slow)
    # data_file = "data.yaml"
    # data_file = Path(data_file)
    # if data_file.is_file():
    #     schedules = yaml.safe_load(data_file.read_text())
    # else:
    #     global_schedule = get_global_schedule()
    #     team_schedules = get_team_schedules()
    #     schedules.extend(global_schedule)
    #     schedules.extend(team_schedules)
    #     with open(data_file, "w") as outfile:
    #         yaml.dump(schedules, outfile, default_flow_style=False, default_style='"')

    # Process the schedules
    print("Processing schedules with a duration...")
    for schedule in schedules:
        # get the current datetime in the schedule's timezone
        sch_current_datetime = dt.datetime.now(pytz.timezone(schedule["Timezone"]))
        # get the scheduled datetime in the schedule's timezone
        sch_datetime = get_datetime_from_time_and_timezone(schedule["Time"], schedule["Timezone"])
        # is it time/day to run this schedule
        day_to_run_now = is_day_to_run(sch_current_datetime, schedule["Day"])
        time_to_run_now = is_time_to_do_it(sch_current_datetime, sch_datetime)
        # get the state and stop datetime
        i_state = schedule["InstanceState"]
        if day_to_run_now and time_to_run_now and schedule["Duration"] != "00:00":
            # is time and day to run and is a schedule with a duration
            action = "None"
            sch_stop_datetime = get_datetime_from_duration(schedule["Duration"])
            if i_state != "running":
                # instance is not running, start it and set the stop datetime tag
                action = "Instance started, stop at " + sch_stop_datetime.isoformat(timespec="minutes")
                start_instance(schedule["InstanceId"])
                set_stop_datetime(schedule["InstanceId"], sch_stop_datetime)
            elif i_state in ["running", "pending"]:
                # instance is running
                if schedule["InstanceStopDatetime"] is not None:
                    # stop datetime tag is set to some datetime
                    i_stop_datetime = dt.datetime.fromisoformat(schedule["InstanceStopDatetime"])
                    if i_stop_datetime < max([i_stop_datetime, sch_stop_datetime]):
                        # this schedule's duration is longer than the current duration
                        # reset the stop datetime tag to the longer datetime
                        action = "Instance is running, stop reset to " + sch_stop_datetime.isoformat(
                            timespec="minutes"
                        )
                        set_stop_datetime(schedule["InstanceId"], sch_stop_datetime)
            print(
                "Workstation: "
                + schedule["Workstation"]
                + " Type:"
                + schedule["Type"]
                + " Day:"
                + str(schedule["Day"])
                + " Time:"
                + schedule["Time"]
                + " Duration:"
                + schedule["Duration"]
                + " Action:"
                + action
            )
    print("Processing schedules with a duration...Done")
    print("")

    print("Getting refreshed global schedule...")
    schedules = []
    global_schedule = get_global_schedule()
    schedules.extend(global_schedule)
    print("Getting refreshed global schedule...Done")
    print("")

    # Assuming there will not be zero duration schedules in team schedules...
    # print("Getting refreshed team schedules...")
    # team_schedules = get_team_schedules()
    # schedules.extend(team_schedules)
    # print("Getting refreshed team schedules...Done")
    # print("")

    print("Processing refreshed schedules without a duration or active schedule...")
    for schedule in schedules:
        # get the current datetime in the schedule's timezone
        sch_current_datetime = dt.datetime.now(pytz.timezone(schedule["Timezone"]))
        # get the scheduled datetime in the schedule's timezone
        sch_datetime = get_datetime_from_time_and_timezone(schedule["Time"], schedule["Timezone"])
        # is it time/day to run this schedule
        day_to_run_now = is_day_to_run(sch_current_datetime, schedule["Day"])
        time_to_run_now = is_time_to_do_it(sch_current_datetime, sch_datetime)
        # get the state and stop datetime
        i_state = schedule["InstanceState"]
        if day_to_run_now and time_to_run_now and schedule["Duration"] == "00:00":
            # is time and day to run and is a schedule without a duration
            action = "None"
            if schedule["InstanceStopDatetime"] is None:
                action = "Instance stopped"
                stop_instance(schedule["InstanceId"])
                delete_stop_datetime(schedule["InstanceId"])
            print(
                "Workstation: "
                + schedule["Workstation"]
                + " Type:"
                + schedule["Type"]
                + " Day:"
                + str(schedule["Day"])
                + " Time:"
                + schedule["Time"]
                + " Duration:"
                + schedule["Duration"]
                + " Action:"
                + action
            )
    print("Processing refreshed schedules without a duration or active schedule...Done")
    print("")

    print("Process instances with a InstanceScheduler:StopDatetime tag that are due to be stopped...")
    stop_instances_with_stop_datetime()
    print("Process instances with a InstanceScheduler:StopDatetime tag that are due to be stopped...Done")
