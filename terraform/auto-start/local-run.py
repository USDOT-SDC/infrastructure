from src.lambda_function import lambda_handler
import json
import datetime
import time
import os
import uuid

class MockContext:
    def __init__(self):
        function_name = os.path.basename(os.path.dirname(__file__))
        now = datetime.datetime.now()
        self.function_name = function_name
        self.function_version = "$LATEST"
        self.invoked_function_arn = f"arn:aws:lambda:us-east-1:123456789012:function:{function_name}"
        self.memory_limit_in_mb = 128
        self.aws_request_id = str(uuid.uuid4())
        self.log_group_name = f"/aws/lambda/{function_name}"
        self.log_stream_name = f"{now.year}/{now.month}/{now.day}/[LATEST]abcdef1234567890"
        self.identity = None  # Normally provided in Cognito/auth scenarios
        self.client_context = None  # Only used for mobile apps

    def get_remaining_time_in_millis(self):
        return int((time.time() + 3) * 1000)  # Simulates 3 seconds remaining


def load_event_from_file(filename):
    with open(filename, "r") as f:
        return json.load(f)


if __name__ == "__main__":
    # Load the event JSON file and instantiate the context
    event = load_event_from_file("local-event.json")
    context = MockContext()

    # Invoke the Lambda function
    response = lambda_handler(event, context)
    
    # Print the response
    print(json.dumps(response, indent=3))
