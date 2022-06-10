#from http import client
# one change
from time import strptime
import boto3
import datetime
import yaml
import pytz
import calendar
import sys

days = ["","monday","tuesday","wednesday","thursday","friday","saturday","sunday"]
region = "us-east-1"

def get_instance_action( iid ):
    ec2 = boto3.resource('ec2',region)
    ec2instance = ec2.Instance(iid)
    action= ''
    for tags in ec2instance.tags:
        if tags["Key"] == 'Action':
            action = tags["Value"]
    return action

def start_stop_instance( workstation,startorstop ):
    print("start/stop the instance")
    ec2 = boto3.resource('ec2',region)
    client = boto3.client('ec2',region)

    try:
        instances = ec2.instances.filter(Filters=[{'Name': 'tag:Name', 'Values': [workstation]}])
    except Exception as e:
        print(e)
        return

    if(startorstop == "start"):
        for instance in instances:
            print(instance.id)
            instance.start()
    elif(startorstop == "stop"):
        for instance in instances:
            if ( get_instance_action(instance.id).tolower() == "stop" ):
                instance.stop()

    print("done with starting the instance")
    

def isin_time_period(start_time, end_time, current_time):
    if start_time < end_time:
        return current_time >= start_time and current_time <= end_time
    else: 
        return current_time >= start_time or current_time <= end_time


def process_daily(rtime,duration,workstation, tz):

    x =  str(rtime)
    rhours = int(x[0:2])
    rminutes = int(x[2:4])

    y =  str(duration)
    dhours = int(y[0:2])
    dminutes = int(y[2:4])
    
    dt_current = datetime.datetime.now(pytz.timezone(tz))
     
    dt_start = dt_current.replace(hour=rhours,minute=rminutes)
    
    dt_end = dt_start + datetime.timedelta(hours = dhours, minutes= dminutes )
    print(dt_current)
    print(dt_start)
    print(dt_end)

    if (dt_current > dt_end):
        print("beyond the end time")
        start_stop_instance(workstation,"stop")
    elif (isin_time_period(dt_start+datetime.timedelta(hours= -1 ),dt_end,dt_current)):
        start_stop_instance(workstation,"start")
    else: 
        print("Leave the instance as is... don't touch it")
def last_day_of_month(date):
    last_day = datetime.datetime(date.year, date.month,calendar.monthlen(date.year, date.month) )
    return last_day.strftime('%Y-%m-%d')

def is_date( date ):
    print("checking if a string conform to the date format")
    try:
       thedate = strptime(date, "%Y-%m-%d")
    except Exception as e:
        print(e)
        return False
    else:
        return thedate


def process_schedule( dict ):
   
    wkst = dict["workstation"]["name"]
    tz = dict["workstation"]["timezone"]

    print("length of dictionary is: ", len(dict))
    for job in dict['workstation']['jobs']:
        print(job["day"])
        if(job["day"].lower() == "daily"):
            print("will start porcessing")
            process_daily(run["time"],run["duration"],wkst,tz)
        elif ( (job["day"].lower()  in days) ):
            #and (datetime.datetime.today().isoweekday == days.index(run["run"]))
            print("day of the week")
            process_daily(job["time"],job["duration"],wkst,tz)
        
        elif ( type( job["day"] ) is int ):
            print(job["day"])
            # if it is negative one, get the last day of the month
            if (int(job["day"] ) < 0):
                #get the last day of the month, compare it to today's date
                if( calendar.monthrange(datetime.datetime.now().year,datetime.datetime.now().month)[1] == datetime.date.now().day ):
                      process_daily(job["time"],job["duration"],wkst,tz)
            elif( int(job["day"] == datetime.datetime.now().day )):
                process_daily(job["time"],job["duration"],wkst,tz)

        elif( type(is_date(job["day"])) is datetime and ( is_date(job["day"].day == datetime.date.today().day ))):
             process_daily(job["time"],job["duration"],wkst,tz)

        else:
            print("we don't know yet")
        
    return 

def lambda_handler(event, context):

    s3 = boto3.resource('s3')
    for bucket in s3.buckets.all(): 
        if bucket.name.startswith("dev.sdc.dot.gov.team") or "wydot" in bucket.name:
            #print( bucket.name)
            #ge all the yaml files contained in the workstations-schedule
            for objects in bucket.objects.filter(Prefix="Workstations-Schedule/"):
                if (objects.key.endswith('yaml') or objects.key.endwith('yml')):
                    print(objects.key)
                    print( objects.get()['Body'].read() )
                    dct = yaml.safe_load( objects.get()['Body'].read() )
                    try:
                        process_schedule( dct )
                    except Exception as e:
                        print(e)