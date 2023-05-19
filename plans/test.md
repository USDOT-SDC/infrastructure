# Version 0.4.3 Test Plan
This Test Plan is designed to prescribe the scope, objectives, test activities and deliverables of the testing activities for the Research Teams.

### In Scope Testing
Verify the following and attach the results to the Pull Request as a comment.
- Check that `{environment}.{domain}.platform.instance-maintenance` has been created
- Copy `s3://{environment}.{domain}.platform.instance-maintenance/infrastructure/utilities/disk-alert-linux.py` to a Linux instance
- Run `py disk-alert-linux.py` to insure it works

### Out of Scope Testing
Verify the following if in scope testing reveals issues or issues are suspected, attach the results to the Pull Request as a comment.
- Log4SDC

### Objectives
The test objectives are to verify the functionality of the infrastructure resources, and should focus on testing the in scope teams to guarantee they work normally in a production environment.
