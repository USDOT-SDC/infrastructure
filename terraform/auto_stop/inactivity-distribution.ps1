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
      <Command>C:\Inactivity\inactivity.bat</Command>
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

# Create and activate a virtual environment
$venvPath = "C:\Inactivity\venv"
if (-Not (Test-Path $venvPath)) {
    python -m venv $venvPath
}

$batchFilePath = "C:\Inactivity\setup.bat"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFilePath`"" -Wait