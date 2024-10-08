# Define the path to the task's XML file
$taskXmlPath = Join-Path -Path $PSScriptRoot -ChildPath "task-schedule.xml"

# Define the task name
$taskName = "auto-stop"

# Register the task using schtasks.exe with SYSTEM user to avoid password prompt
schtasks.exe /Create /TN $taskName /XML $taskXmlPath /RU SYSTEM /F
