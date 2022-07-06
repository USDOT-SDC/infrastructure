# Version 0.1.0 Test Plan
This Test Plan is designed to prescribe the scope, objectives, test activities and deliverables of the testing activities for the Research Teams.

### In Scope Testing
Verify the following and attach the results to the Pull Request as a comment.
- Check that the following have deployed correctly
  - Lambda: instance-scheduler
  - IAM Role: instance_scheduler_role
- Ensure the function works IAW the following process flow  
  ![Instance Scheduler](./Instance%20Scheduler.png "Instance Scheduler")

### Out of Scope Testing
Verify the following if in scope testing reveals issues or issues are suspected, attach the results to the Pull Request as a comment.
- Other modules

### Objectives
The test objectives are to verify the functionality of the infrastructure resources, and should focus on testing the in scope teams to guarantee they work normally in a production environment.
