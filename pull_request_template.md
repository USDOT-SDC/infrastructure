## Pull Request Information
>__Instructions__  
> - Repository should be a link to the repo
> - Don’t forget to move the tag to the head of the main branch after the Pull Request is merged
> - Version numbers should have three segments: Major.Minor.Patch/Bug and be a link to the tag (tree/0.0.0/)
> - Release Type
>   - Major: Architectural or significant functionality changes
>   - Minor: Routine minor enhancements to existing functionality
>   - Fast Track: Functionality enhancements with limited risk
>   - Hot Fix: Solutions for defects impacting expected user functionality

| Proposed Release Date  | Repository                                                    | Version/Tag                                                                         | Release Type  | Risk Type  | Expected Downtime  |
|------------------------|---------------------------------------------------------------|-------------------------------------------------------------------------------------|---------------|------------|--------------------|
| 2022-00-00             | [infrastructure](https://github.com/USDOT-SDC/infrastructure) | [0.0.0 vs 0.0.1](https://github.com/USDOT-SDC/infrastructure/compare/0.0.0...0.0.1) | Fast Track    | Low        | None               |

## Release
> __Instructions__
> - Don’t forget to move the tag to the head of the main branch after the Pull Request is merged
- https://github.com/USDOT-SDC/infrastructure/releases/tag/0.0.1

## Release Notes
> __Instructions__
> - Provide link to the Release Notes file
- [Release Notes](https://github.com/USDOT-SDC/infrastructure/blob/0.0.1/RELEASE-NOTES.md)

## Summary
> __Instructions__
> - Provide a summary of the change to be implemented, references to Jira/Confluence pages for background information, etc.
> - Provide benefits of implementing the change
- Summary of changes

## Work Items
> __Instructions__
> - Provide a link to the Epic and related Jira stories
> - Pull Requests without links to the Epic and related Jira stories will not be moved to In Approval status
- https://securedatacommons.atlassian.net/browse/SDC-0000
- https://securedatacommons.atlassian.net/browse/DESK-000

## Release Notifications
> __Instructions__
> - Only applies when the change will affect what users see or how they interact with the platform
> - If it does not apply, delete the email templates

### Upcoming Release Email Template
__To:__  
Designate Recipients
- All of CRM
- Active Projects
- Active Users
- Specific Project, etc...

__Subject__  
Secure Data Commons: Upcoming Release, 2022-00-00, Infrastructure: Release Title

__Body__  
Secure Data Commons Community:
We are making changes to the Secure Data Commons' (SDC) infrastructure this week. Deployment of this release will occur on Xday, Month DD, 2020 from x pm to x pm ET. 
Connectivity to the SDCs' infrastructure will be <available or unavailable> during this deployment window. 
We will send a notification email once the deployment is complete.

This release includes
1. New features being release:<describe the new functionality in terms that are easy for anyone to understand. Where possible reference any training materials.>
2. Bug Fixes being addressed:<describe the bug fix in terms that are easy for anyone to understand. Where possible reference any training materials.>

What you need to know:
<text describing any user required actions post release, support processes in place immediately after release, etc>

For more information:  
As always, don’t hesitate to contact the SDC Support Team with any comments or questions, we will be happy to help.

Thank you,  
SDC Support Team

### Post Release Email Template
__To:__  
Designate Recipients
- All of CRM
- Active Projects
- Active Users
- Specific Project, etc...

__Subject__  
Secure Data Commons: Update, Infrastructure: Release Title  
__Body__  
Secure Data Commons Community:
We have successfully deployed the latest changes to the Secure Data Commons' (SDC) infrastructure.

This release included
1. New features being release:<describe the new functionality in terms that are easy for anyone to understand. Where possible reference any training materials.>
2. Bug Fixes being addressed:<describe the bug fix in terms that are easy for anyone to understand. Where possible reference any training materials.>

What you need to know:
<text describing any user required actions post release, support processes in place immediately after release, etc>

For more information:  
As always, don’t hesitate to contact the SDC Support Team with any comments or questions, we will be happy to help.

Thank you,  
SDC Support Team

## Cost Impacts
> __Instructions__
> - Provide details on system cost impacts.
- System cost impacts

## User Guide Updates
> __Instructions__
> - Provide details on what training materials have been created, include a link
- User Guide Chapter

## Process, Procedure and Work Instruction
- [Process: Development](https://securedatacommons.atlassian.net/wiki/spaces/DO/pages/1332379871)
  - [Procedure: Infrastructure](https://securedatacommons.atlassian.net/wiki/spaces/DO/pages/2437218305)
    - [WI: Infrastructure, Infrastructure Deployment](https://securedatacommons.atlassian.net/wiki/spaces/DO/pages/2501017629)

## Impacted System Components
> __Instructions__
> - Provide details on what system components are affected, if any
- System component impact details

## Data Load/Processing Impact
> __Instructions__
> - If there is an impact, the requester will need to specify affected systems and before they start implementing the Pull Request, add a count of records.
> - The next day (or next load interval) you will need to check and put the next load count. 
> - Individuals will need to record the counts (expected/actual) in this section.
> - If there are manual data checks happening within an automated instance (i.e. manually bringing up an EC2 instance), then there need to be data checks after the job has run automatically.
- Count of records
  - Before: 
  - After: 

## Release Type/Risk Level classification justification
> __Instructions__
> - Provide details on the Release Type, Risk Level and Risk Level Justification
> - Risk Levels:
>   - 0-2: Low
>   - 3-4: Medium
>   - 5-7: High
- Release Type: Fast Track
- Risk Level: Low (0)

### Risk Level Justification
| Risk | Level |
|:---- |:----- |
| Are there any modifications to system configuration?                           | 0  |
| Are there any additions or modifications to security settings?                 | 0  |
| Is a new workflow introduced or an existing workflow altered significantly?    | 0  |
| Is user behavior affected as a result of this change?                          | 0  |
| Is service outage required to deploy this change?                              | 0  |
| Are new system inter-dependencies introduced?                                  | 0  |
| Has this type of change been attempted before successfully? (Yes = 0, No = 1)  | 0  |

## Plans
> __Instructions__
> - Provide a link to the plans directory of the repo at this release tag (/tree/0.0.0/plans)
- https://github.com/USDOT-SDC/infrastructure/tree/0.0.1/plans

### Test Results
> __Instructions__
> - After deployment, check off the items from the Test Plan
- [ ] Test Item One
- [ ] Test Item Two

## Code Review Checklist
- [ ] **Avoid Hardcoding**  
Any string literal values that are likely to change should not be hardcoded and instead put into a config file or something like the AWS Systems Manager Parameter Store. 
This would obviously include any secrets but would also include things URLs, user names, target services, etc. For example, if posting to an SNS topic, we might consider 
externalizing the topic name to make it configurable. For cases where this seems like overkill, a good compromise is hardcoding a default value. In other words, attempt 
to read from an external configuration (e.g. Parameter Store) but use the default value if not found. This does not require much more code but gives you an option to 
change configuration later if needed.

- [ ] **Cyclomatic Complexity**  
Avoid writing functions that have too many nested decision points (conditional logic, looping, etc.). Generally, if a function has more than about 10 decision points 
(adding a point for each if/else/for/while, etc.) it should be broken up into multiple functions.  

- [ ] **Code Reusability**  
We must avoid copying-and-pasting code in multiple places. If we have utility functions that would be useful they should be put in a common library for reuse. 
For Lambda functions, this may mean creating a Lambda layer for utility code that can be reused across multiple Lambdas. For regular Python code, this might involve 
creating a custom Python library. Even if this is the first time writing a piece of code, if it can be made generic and put into a common library/package, we should 
strongly consider doing this. 

- [ ] **Self-Documenting Code**  
Code should include comments for clarity when appropriate but should also be self-documenting to the extent possible. This means using meaningful function and variable 
names to help indicate when the function or variable is being used for. Comments above a function that explain the inputs and outputs are useful but not necessary for 
code that has a good function name and can be understood by a junior developer.

- [ ] **Security**  
Are secrets being utilized in the code? If so, are they handled properly and not logged to output or exposed. If necessary, is appropriate authentication in place for the code 
to be invoked? Is input data from non-trusted sources appropriately validated and/or sanitized?  
Check for the following:
  - Passwords
  - Private Tokens/Keys
  - Account Numbers
  - Usernames
  - Email Addresses

## Users to Notify
> __Instructions__
> - Provide a list or group of users affected by the change
- SDC User Community
- All Waze Researchers
- Acme Data Provider

## Security Impact Analysis (SIA)
> __Instructions__
> - Review [WI: Performing a Security Impact Analysis (SIA)](https://securedatacommons.atlassian.net/wiki/spaces/DO/pages/2642935856) to determine if a SIA is required
> - If required, copy/paste the SIA template into the CRB here
- No

## Meets Definition of Ready?
> __Instructions__
> - Delete all Instructions Info Panels
> - Add check to validate that its ready for deployment
- No
