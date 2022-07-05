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


def get_instance_turnoff_time(iid):
    '''
    get the global turnoff time from the parameter store..
    '''
    print("in get instance turnoff time")
    turnoff_time = ''
    try:
        ec2 = boto3.resource('ec2', region_name=region)
        ec2instance = ec2.Instance(iid)

        for tags in ec2instance.tags:
            if tags["Key"] == 'TurnoffTime':
                turnoff_time = tags["Value"]
        print("the time to turnoff this instance down is: ", turnoff_time)
    except Exception as e:
        print(e)
    return turnoff_time


def instance_is_running(iid):
    '''returns true if the instance is running to starting'''
    print("checking the instance status")
    try:
        ec2 = boto3.resource('ec2', region_name=region)
        instance = ec2.Instance(iid)
        if (instance.state['Name'] == 'running') or (instance.state['Name'] == 'pending'):
            print("instance is running")
            return True
        else:
            print("instance is not running")
            return False
    except Exception as e:
        print(e)


def set_turnoff_time(iid, sdtime):
    ''' set the shutdown time tag to signal when this instane could ready for shutdown. it is a calculated
    field.  start time of the job up to the end time of the last scheduled job
    '''
    print("in set shutdown time")
    print("turnoff time for this job is: ", sdtime)
    try:
        ec2 = boto3.resource('ec2', region_name=region)
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
                    'Key': 'TurnoffTime',
                    'Value': sdtime
                },
            ]
        )
    except Exception as e:
        print(e)


def compare_times(first, second):
    '''returns true if the first time is samller than second time, false otherwise'''
    print("in compare times")
    print("first time: ", first)
    print("second time: ", second)
    try:
        now = datetime.datetime.now()
        fdate = now.replace(hour=int(first[0:2]), minute=int(first[3:5]))
        sdate = now.replace(hour=int(second[0:2]), minute=int(second[3:5]))
        if(fdate < sdate):
            return True
        else:
            return False
    except Exception as e:
        print(e)


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
        sdtime = get_instance_turnoff_time(iid)
        if(sdtime != ""):
            print("this instance was running a job already. update end time")
            # if the turnoff time already set in the instance tag is less than the turnoff time
            # passed in , update the turnoff time, otherwise leave it alone
            if(compare_times(sdtime, endtime)):
                set_turnoff_time(iid, endtime)
    else:
        print("this instance was not running. start it and upate the end time")
        instance.start()
        set_turnoff_time(iid, endtime)

    print("done with starting the instance")


def remove_turnoff_tag(iid):
    '''remove the shutdown tag when done with the instance'''
    print("in remove shutdown tag")
    try:
        client = boto3.client('ec2', region_name=region)
        client.delete_tags(Resources=[iid], Tags=[{"Key": "TurnoffTime"}])
    except Exception as e:
        print(e)


def stop_instance(workstation, current_time):
    print("in stop instance")
    print("instance name, ", workstation)

    ec2c = boto3.resource('ec2', region_name=region)
    print("after creating ec2 resource")
    instances = ec2c.instances.filter(
        Filters=[{'Name': 'tag:Name', 'Values': [workstation]}])
    print("the number of instnace is ", len(list(instances)))
    print("the first instance is: ", list(instances)[0])

    instance = list(instances)[0]
    # get the shutdown tag and compare to current time
    when_to_shutdown = get_instance_turnoff_time(instance.id)
    if(when_to_shutdown != ""):
        if(datetime.datetime.strptime(when_to_shutdown, "%Y-%m-%d").date() >= current_time):
            remove_turnoff_tag(instance.id)
            instance.stop()

    print("don with stopping the instance")


def isin_time_period(start_time, end_time, current_time):
    if start_time < end_time:
        return current_time >= start_time and current_time <= end_time
    else:
        return current_time >= start_time or current_time <= end_time


def process_daily(rtime, duration, workstation, tz):
    print("in process daily")
    try:
        print("rtime is:", rtime)
        x = str(rtime)
        rhours = int(x[0:2])
        rminutes = int(x[3:5])
        print("rhours is: ", rhours)
        print("rminutes is: ", rminutes)

        print("duration is: ", duration)

        y = str(duration)
        dhours = int(y[0:2])
        dminutes = int(y[3:5])

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
        start_instance(workstation, dt_end.strftime("%H:%M"))
    else:
        print("Leave the instance as is... don't touch it")


def check_turnoff_time(wkst, tz):
    '''checking if it is time to turnoff all our machines. saving energy'''
    print("in check_turnoff_time")
    ssm = boto3.client('ssm', region_name='us-east-1')
    ec2_tft = ssm.get_parameter(
        Name='/common/secrets/ec2_turnoff_time', WithDecryption=False)
    tt_time = ec2_tft['Parameter']['Value']
    print("the turnoff parameter value is: ", tt_time)
    hours = int(tt_time[0:2])
    minutes = int(tt_time[3:5])
    dt_current = datetime.datetime.now(pytz.timezone(tz))
    dt_totime = dt_current.replace(hour=hours, minute=minutes)

    if (isin_time_period(
            dt_current, dt_current + datetime.timedelta(hours=1), dt_totime)):
        print("it is time to shutdown this instance")
        turnoff_instane(wkst)


def turnoff_instane(wkst):
    print("in turnoff instance")
    try:
        ec2c = boto3.resource('ec2', region_name=region)
        print("after creating ec2 resource")
        instances = ec2c.instances.filter(
            Filters=[{'Name': 'tag:Name', 'Values': [wkst]}])

        instance = list(instances)[0]
        remove_turnoff_tag(instance.id)
        instance.stop()
    except Exception as e:
        print(e)


def process_schedule(dict):
    print("in process schedule")
    wkst = dict["workstation"]["name"]
    tz = dict["workstation"]["timezone"]

    # before parsing executing the yaml file, check the turnoff parameter and turnoff the machine if it is
    # after this time, clear the shutoff tag and turnoff the machine
    check_turnoff_time(wkst, tz)

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
