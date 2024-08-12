<#
Description:
    This script creates a scheduled task for automatically shutting down the computer when idle,
    and sets up a virtual environment for running a Python script that performs the shutdown operation.

    The scheduled task is registered under the SYSTEM user to avoid password prompts, and it runs
    a Python script (`auto-stop.py`) located in the specified virtual environment (`venv`).

    Requirements:
    - PowerShell running with administrative privileges.
    - Python installed with 'python' executable accessible in PATH.
    - 'auto-stop.py' script and 'requirements.txt' file located in 'C:\auto-shutdown'.

Steps:
1. Define the task XML content with S4U LogonType for creating a scheduled task.
2. Save the task XML content to a temporary file.
3. Register the scheduled task using schtasks.exe under SYSTEM user.
4. Clean up the temporary XML file after registration.
5. Create and activate a virtual environment located at 'C:\auto-shutdown\venv'.
6. Install required Python packages specified in 'requirements.txt' within the virtual environment.

Note: Ensure proper configuration of 'auto-stop.py' script for expected behavior during shutdown.

Author: SDC\wsharp
Date: 2024-07-05
#>

# Define the task XML content with S4U LogonType
$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2024-06-03T18:15:19.5315083</Date>
    <Author>SDC\wsharp</Author>
    <URI>\auto-shutdown</URI>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <UserId>SDC\wsharp</UserId>
      <LogonType>S4U</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <RunOnlyIfIdle>true</RunOnlyIfIdle>
    <IdleSettings>
      <Duration>PT1H</Duration>
      <WaitTimeout>PT1H</WaitTimeout>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>true</RestartOnIdle>
    </IdleSettings>
  </Settings>
  <Triggers>
    <IdleTrigger>
      <Repetition>
        <Interval>PT5M</Interval>
      </Repetition>
    </IdleTrigger>
  </Triggers>
  <Actions Context="Author">
    <Exec>
      <Command>C:\auto-shutdown\venv\Scripts\python.exe </Command>
      <Arguments>C:\auto-shutdown\auto-stop.py</Arguments>
    </Exec>
  </Actions>
</Task>
"@

# Save the task XML content to a temporary file
$taskXmlPath = "$env:TEMP\auto-shutdown.xml"
$taskXml | Out-File -FilePath $taskXmlPath -Encoding Unicode

# Define the task name
$taskName = "auto-shutdown"

# Register the task using schtasks.exe with SYSTEM user to avoid password prompt
schtasks.exe /Create /TN $taskName /XML $taskXmlPath /RU SYSTEM /F

# Clean up the temporary file
Remove-Item -Path $taskXmlPath

# Define the path to your virtual environment
$venvPath = "C:\auto-shutdown\venv"

# Check if the virtual environment exists and remove it if so
if (Test-Path $venvPath) {
    Remove-Item -Path $venvPath -Recurse -Force
}

# Create a new virtual environment
python -m venv $venvPath

# Activate the virtual environment (assuming it's a batch file on Windows)
$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
if (Test-Path $activateScript) {
    & $activateScript
}

# Install packages from requirements.txt into the virtual environment
pip install --no-cache-dir -r C:\auto-shutdown\requirements.txt

# Deactivate the venv
deactivate
