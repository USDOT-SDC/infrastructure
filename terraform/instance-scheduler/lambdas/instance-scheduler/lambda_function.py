from pydoc import cli
from time import strptime
from tokenize import Floatnumber
import boto3
import datetime
import yaml
import pytz
import calendar
import sys

days = ["", "monday", "tuesday", "wednesday",
        "thursday", "friday", "saturday", "sunday"]
region = "us-east-1"


def get_instance_shutdown_time(iid):
    print("in get instance shutdown time")
    ec2 = boto3.resource('ec2', region)
    ec2instance = ec2.Instance(iid)
    shutdown_time = ''
    for tags in ec2instance.tags:
        if tags["Key"] == 'ShutdownTime':
            shutdown_time = tags["Value"]
    print("the time to shut this instance down is: ", shutdown_time)
    return shutdown_time


def instance_is_running(iid):
    print("checking the instance status")
    ec2 = boto3.resource('ec2', 'us-east-1')
    instance = ec2.Instance(iid)
    if instance.state['Name'] == 'running':
        print("instance is running")
        return True
    else:
        print("instance is not running")
        return False


def set_shutdown_time(iid, sdtime):
    print("in set shutdown time")
    ec2 = boto3.resource('ec2', region_name='us-east-1')
    print("let's get the instance first")
    instances = ec2.instances.filter(
        InstanceIds=[
            iid,
        ],
    )
    print("now set the tag")
    response = list(instances)[0].create_tags(
        Resources=[
            iid,
        ],
        Tags=[
            {
                'Key': 'ShutdownTime',
                'Value': sdtime
            },
        ]
    )


def start_instance(workstation, endtime):
    print("start the instance")
    print("instance name, ", workstation)

    ec2c = boto3.resource('ec2', region_name='us-east-1')
    print("after creating ec2 resource")
    instances = ec2c.instances.filter(
        Filters=[{'Name': 'tag:Name', 'Values': [workstation]}])
    print("the number of instnace is ", len(list(instances)))
    print("the first instance is: ", list(instances)[0])
    instance = list(instances)[0]
    iid = list(instances)[0].id
    # get the instance status, if it is already running check the flag
    # if it is not set leave it alone, otherwise update with the latst time
    # if the machine is not running start it and set the flag
    if (instance_is_running(iid)):
        # get the flag value
        sdtime = get_instance_shutdown_time(iid)
        if(sdtime != ""):
            print("this instance was running a job already. update end time")
            set_shutdown_time(iid, endtime)
    else:
        print("this instance was not running. start it and upate the end time")
        instance.start()
        set_shutdown_time(iid, endtime)

    print("done with starting the instance")


def remove_tag(iid):
    client = boto3.client('ec2', region_name='us-east-1')
    client.delete_tags(Resources=[iid], Tags=[{"Key": "ShutdownTime"}])


def stop_instance(workstation, current_time):
    print("in stop instance")
    print("instance name, ", workstation)

    ec2c = boto3.resource('ec2', region_name='us-east-1')
    print("after creating ec2 resource")
    instances = ec2c.instances.filter(
        Filters=[{'Name': 'tag:Name', 'Values': [workstation]}])
    print("the number of instnace is ", len(list(instances)))
    print("the first instance is: ", list(instances)[0])

    instance = list(instances)[0]
    # get the shutdown tag and compare to current time
    when_to_shutdown = get_instance_shutdown_time(instance.id)
    if(when_to_shutdown != ""):
        if(datetime.datetime.strptime(when_to_shutdown, "%Y-%m-%d").date() >= current_time):
            remove_tag(instance.id)
            instance.stop()

    print("don with stopping the instance")


def isin_time_period(start_time, end_time, current_time):
    if start_time < end_time:
        return current_time >= start_time and current_time <= end_time
    else:
        return current_time >= start_time or current_time <= end_time


def process_daily(rtime, duration, workstation, tz):
    try:
        print("rtime is:", rtime)
        x = str(rtime)
        rhours = int(x[0:2])
        rminutes = int(x[3:5])
        print("rhours is: ", rhours)
        print("rminutes is: ", rminutes)

        y = str(duration)
        dhours = int(y[0:2])
        dminutes = int(y[3:5])
        print("duration: ", duration)
        print("dhours is: ", dhours)
        print("dminutes is: ",  dminutes)
    except:
        print("start time or duration of the job are invalid or not well formatted")
        return

    dt_current = datetime.datetime.now(pytz.timezone(tz))

    dt_start = dt_current.replace(hour=rhours, minute=rminutes)

    dt_end = dt_start + datetime.timedelta(hours=dhours, minutes=dminutes)
    print("current time ", dt_current)
    print("start time ", dt_start)
    print("end time ", dt_end)

    if (dt_current > dt_end):
        print("This job starting time is already gone, should stop the instance")
        stop_instance(workstation, dt_current)
    elif (isin_time_period(dt_start+datetime.timedelta(hours=-1), dt_end, dt_current)):
        print("let's start the worksation")
        start_instance(workstation, dt_end.strftime("%Y-%m-%d"))
    else:
        print("Leave the instance as is... don't touch it")


def process_schedule(dict):

    wkst = dict["workstation"]["name"]
    tz = dict["workstation"]["timezone"]

    for job in dict['workstation']['jobs']:
        print("run this type of job: ", job["day"])
        if(job["day"].lower() == "daily"):
            print("will start porcessing daily, run daily at a specific time")
            process_daily(job["time"], job["duration"], wkst, tz)
            continue

        elif ((job["day"].lower() in days) and (datetime.date.today().strftime("%A").lower() == job["day"].lower())):
            print("day of the week")
            process_daily(job["time"], job["duration"], wkst, tz)

        elif(datetime.datetime.strptime(job["day"], "%Y-%m-%d").date() == datetime.date.today()):

            print("processing a date")
            print("config date: ", job["day"])
            print("actual date: ", datetime.date.today())
            process_daily(job["time"], job["duration"], wkst, tz)
            continue

        else:
            print("unknow option")


def lambda_handler(event, context):
    # or "wydot" in bucket.name
    s3 = boto3.resource('s3')
    for bucket in s3.buckets.all():
        if (bucket.name.startswith("dev.sdc.dot.gov.team")):
            print("in " + bucket.name + " bucket")
            # ge all the yaml files contained in the workstations-schedule
            for object in bucket.objects.filter(Prefix="Workstations-Schedule/"):
                if (object.key.endswith('yaml') or object.key.endswith('yml')):
                    print(object.key)
                    dct = yaml.safe_load(object.get()['Body'].read())
                    # let's parse and execute the yaml file
                    process_schedule(dct)
