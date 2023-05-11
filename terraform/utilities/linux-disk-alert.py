import boto3 
import os
import json 
import subprocess
from ec2_metadata import ec2_metadata                                                                                                                                                                    
#stat = shutil.disk_usage("/home")
#print(stat.total)
#print(stat.used)
#print(stat.free)

def get_env():
	ssm_client = boto3.client('ssm', region_name='us-east-1')
	response = ssm_client.get_parameter(Name='environment')
	return response['Parameter']['Value']

env = get_env()

if env == "prod":
    endpoint_urll = "https://vpce-028bcae67fc0a12b0-nz0ik0fh.lambda.us-east-1.vpce.amazonaws.com/"
elif env == "dev":
    endpoint_urll = "https://vpce-09a0e5eacbc1f5421-iuyi715c.lambda.us-east-1.vpce.amazonaws.com/"
else:
    endpoint_urll = ""


lambda_client = boto3.client(
	'lambda', 
	region_name = "us-east-1",
	endpoint_url=endpoint_urll)


def send(payload):
	this_payload = {}
	this_payload['type'] = 'email'
	this_payload['to_addresses'] = payload.get('addresses')
	this_payload['subject'] = payload.get('subject')
	this_payload['body_text'] = payload.get('body_text')
	this_payload['reply_to_addresses'] = payload.get('addresses')
	response = lambda_client.invoke(
    	FunctionName='research_teams_notification_service',
    	Payload=json.dumps(this_payload)
	)
	return_response = {
    	'StatusCode': response.get('StatusCode'),
    	'RequestId': response.get('ResponseMetadata').get('RequestId')
    	}
	return return_response

server_name = ec2_metadata.private_hostname
email_payload = {
	"addresses": ["hamza.abdelghani.ctr@dot.gov" ],
	"subject": "Testing the disk utility", 
	"body_text": server_name + " is almost out of disk space"
}


#from ec2_metadata import ec2_metadata

threshold = 90
partition = '/'
df = subprocess.Popen(['df','-h'], stdout=subprocess.PIPE)
for line in df.stdout:
	#print(line)
	splitline = line.decode().split()
	#if (splitline[5] == partition) :
		#print(splitline[5])
	#if int(splitline[4][:-1]) > threshold:
#	print(type(splitline[4][:-1]))
	try:
		actual = int(splitline[4][:-1])
		if actual > threshold:
			email_response = send(email_payload)
			print("sent out the email notification")
	except ValueError:
		pass  # do nothing!
		#print("it is an int")
		#	print("here u go")
		#	print("one to report ")
		#	email_response = send(email_payload)
		#	print(email_response)


