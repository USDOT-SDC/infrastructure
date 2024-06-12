# SDC Infrastructure Release Notes
We’re now releasing SDC Infrastructure: Version 0.4.2.

# Get This Release
​To deploy this release, select this version's tag and follow the instructions in the Deployment Plan.

## Version 0.5.0 (2024-06-07)
### Changes
- Add new token generator API
- Add Instance Auto-start Lambda and DynamoDB tables for auto-starts and maintenance-windows
- Add VPC Endpoint for DynamoDB Gateway

## Version 0.4.4 (2023-05-22)
### Changes
- Update instance scheduler to read global schedule from S3, not parameter store

## Version 0.4.3 (2023-05-17)
### Changes
- Add instance maintenance bucket
- Add disk alert script for Linux instances
- Log4SDC cleanup

## Version 0.4.2 (2023-04-06)
### Changes
- Log4SDC: Add additional validation for setting up custom log4sdc notification topics with configuration

## Version 0.4.1 (2022-11-04)
### Changes
- Instance Scheduler: Add logging for reading global schedule from parameter store

## Version 0.4.0 (2022-08-31)
### Changes
- Instance Scheduler: Add global schedule function

## Version 0.3.0 (2022-08-18)
### Changes
- Log4SDC: Add ability for individual teams to subscribe to team-specific alert notifications

## Version 0.2.0 (2022-08-17)
### Changes
- Add backup bucket

## Version 0.1.0 (2022-07-08)
### Changes
- Add Instance Scheduler function

### Technical Changes
- None

### Fixed Bugs
- None
