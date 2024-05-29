import lambda_function
import json

if __name__ == "__main__":
    with open("dev-test-event.json", "r") as e:
        event = json.load(e)
    context = None
    lambda_function.lambda_handler(event, context)
