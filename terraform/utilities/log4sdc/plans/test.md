# Test Plan

[v1.2](https://github.com/USDOT-SDC/log4sdc/tree/1.2)

## Log message ingest setup
* Log on into the AWS Console for the SDC system account, navigate to the Lambda configuration
* Create a test function with Python 3.7+ runtime
  * Assign prod-lambda-test-role for security role
* Add the latest versions of these lambda layers: log4sdc, requests_aws4auth
* Add this code to the function:

```
import json
from common.logger_utility import *

import time


def lambda_handler(event, context):

    config = {
    'project': 'FOO', 
    'team': 'FOO-BAR', 
    'sdc_service': 'DATA_INGEST', 
    'component': 'log4sdc-common', 
    }
    
    t0 = time.perf_counter()
    LoggerUtility.init(config=config)
    t1 = time.perf_counter()
    print(f't0: {t0}, t1: {t1}, diff: {t1 - t0}')
    # LoggerUtility.setLevel('DEBUG')
    LoggerUtility.logDebug("DEBUG Test LoggerUtility")
    t2 = time.perf_counter()
    print(f't1: {t1}, t2: {t2}, diff: {t2 - t1}')
    LoggerUtility.logInfo("INFO Test LoggerUtility")
    LoggerUtility.logWarning("WARN Test LoggerUtility")
    LoggerUtility.logError("ERROR Test LoggerUtility")
    LoggerUtility.logCritical("CRITICAL Test LoggerUtility")
    LoggerUtility.alert("ALERT Test LoggerUtility")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Log4SDC Lambda!')
    }

```

* Execute function test. Make sure there are no errors and that similar printout is produced:

```
START RequestId: ac989864-6dca-42b5-b1d5-1995edf0018d Version: $LATEST
'LOG_LEVEL'
t0: 650.784622656, t1: 652.382796304, diff: 1.5981736479999427
t1: 652.382796304, t2: 652.665399513, diff: 0.2826032090000581
[INFO]	2022-05-19T19:06:47.098Z	ac989864-6dca-42b5-b1d5-1995edf0018d	INFO Test LoggerUtility
[WARNING]	2022-05-19T19:06:47.353Z	ac989864-6dca-42b5-b1d5-1995edf0018d	WARN Test LoggerUtility
[ERROR]	2022-05-19T19:06:47.599Z	ac989864-6dca-42b5-b1d5-1995edf0018d	ERROR Test LoggerUtility
[CRITICAL]	2022-05-19T19:06:48.121Z	ac989864-6dca-42b5-b1d5-1995edf0018d	CRITICAL Test LoggerUtility
[ERROR]	2022-05-19T19:06:48.657Z	ac989864-6dca-42b5-b1d5-1995edf0018d	ALERT Test LoggerUtility
END RequestId: ac989864-6dca-42b5-b1d5-1995edf0018d
REPORT RequestId: ac989864-6dca-42b5-b1d5-1995edf0018d	Duration: 3992.53 ms	Billed Duration: 3993 ms	Memory Size: 128 MB	Max Memory Used: 73 MB	Init Duration: 629.17 ms

```

## ElasticSearch log message repository verification
* Log on into ElasticSearch Kibana interface (through AWS console OpenSearch view)
* Navigate to Discover section
* Select "log4sdc-*" index pattern from the drop down control under "Add a filter" 
* Select "This month" for the time range, or another appropriate value to make sure that your messages are included
* Verify that the messages with all data appear in the list of log messages.


