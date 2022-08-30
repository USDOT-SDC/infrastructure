import lambda_function


if __name__ == "__main__":
    event = None
    context = None
    lambda_function.lambda_handler(event, context)
