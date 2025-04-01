# Local Development
1. Run: `local-setup.cmd`
   1. If the virtual environment does not exist,
      1. the script creates the virtual environment,
      1. activates the virtual environment,
      1. and installs the required packages.
   1. If it does exist, 
      1. the script activates the virtual environment,
      1. and updates the required packages.
   1. The script exits leaving the virtual environment active.
1. Run: `local-run.py`
   1. The script imports the Lambda function from `./src/lambda_function.py`
   1. Loads the event JSON file
   1. Instantiates the mock context
   1. Invokes the Lambda handler
   1. Prints the response
