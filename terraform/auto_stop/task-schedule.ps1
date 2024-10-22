$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
$taskScheduleLogPath = Join-Path -Path $PSScriptRoot -ChildPath "task-schedule.log"
Start-Transcript -LiteralPath $taskScheduleLogPath -append

function Remove-ItemIfExists {
    param (
        [string]$Path
    )

    if (Test-Path $Path) {
        Remove-Item $Path -Force -Recurse
        Write-Host "Item at '$Path' removed successfully."
    } else {
        Write-Host "Item at '$Path' does not exist."
    }
}

function Remove-ScheduledTaskIfExists {
    param (
        [string]$TaskName
    )

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Scheduled task '$TaskName' removed successfully."
    } else {
        Write-Host "Scheduled task '$TaskName' does not exist."
    }
}

function New-OrUpdateScheduledTaskFromXML {
    param (
        [string]$TaskName,
        [string]$XmlFilePath
    )

    # Check if the XML file exists
    if (-not (Test-Path $XmlFilePath)) {
        Write-Host "Error: XML file '$XmlFilePath' does not exist." -ForegroundColor Red
        return
    }

    # Load the XML content from the file
    $xmlContent = Get-Content $XmlFilePath | Out-String

    # Check if the task already exists
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        try {
            # Update the existing task with the new XML definition
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Register-ScheduledTask -TaskName $TaskName -Xml $xmlContent -Force
            Write-Host "Scheduled task '$TaskName' updated successfully."
        } catch {
            Write-Host "Error updating scheduled task: $_" -ForegroundColor Red
        }
    } else {
        try {
            # Create a new task using the XML definition
            Register-ScheduledTask -TaskName $TaskName -Xml $xmlContent -Force
            Write-Host "Scheduled task '$TaskName' created successfully from XML."
        } catch {
            Write-Host "Error creating scheduled task: $_" -ForegroundColor Red
        }
    }
}

# Remove old task
Remove-ScheduledTaskIfExists -TaskName "auto-shutdown"

# Remove old directory
Remove-ItemIfExists -Path "C:\auto-shutdown"

# Define the path to the new task's XML file
$taskXmlPath = Join-Path -Path $PSScriptRoot -ChildPath "task-schedule.xml"
# Create/Update new task
New-OrUpdateScheduledTaskFromXML -TaskName "auto-stop" -XmlFilePath $taskXmlPath
Get-ScheduledTaskInfo -TaskName "auto-stop"

# Start the task
Start-ScheduledTask -TaskName "auto-stop"

Stop-Transcript
