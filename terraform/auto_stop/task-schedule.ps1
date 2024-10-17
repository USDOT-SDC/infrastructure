# Delete old auto-shutdown task
schtasks.exe /Delete /TN "auto-shutdown" /F

# Delete old auto-shutdown directory
Remove-Item -LiteralPath "C:\auto-shutdown" -Force -Recurse

# Define the path to the task's XML file
$taskXmlPath = Join-Path -Path $PSScriptRoot -ChildPath "task-schedule.xml"
# Write-Host $taskXmlPath

# Define the task name
$taskName = "auto-stop"

# Delete, create/recreate and run the task with SYSTEM user to avoid password prompt
schtasks.exe /Delete /TN $taskName /F
schtasks.exe /Create /TN $taskName /XML $taskXmlPath /RU SYSTEM /F
schtasks.exe /Run /TN $taskName
