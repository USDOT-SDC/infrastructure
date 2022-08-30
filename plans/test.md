# Version 0.4.0 Test Plan
This Test Plan is designed to prescribe the scope, objectives, test activities and deliverables of the testing activities for the Research Teams.

### In Scope Testing
Verify the following and attach the results to the Pull Request as a comment.
- Check that the following have deployed correctly
  - Lambda: instance-scheduler
- Using [sample_global_schedule.yaml](terraform\instance-scheduler\lambdas\instance-scheduler\sample_global_schedule.yaml), setup the global schedule parameter store
- Observe that instances are started and stopped by the instance-scheduler

### Out of Scope Testing
Verify the following if in scope testing reveals issues or issues are suspected, attach the results to the Pull Request as a comment.
- Log4SDC

### Objectives
The test objectives are to verify the functionality of the infrastructure resources, and should focus on testing the in scope teams to guarantee they work normally in a production environment.
