<#
.Description
Logs the message to the log file.
Returns: none
#>
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = "auto-stop.log"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    
    try {
        # Append the log entry to the specified log file
        Add-Content -Path $LogFilePath -Value $logEntry
    }
    catch {
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
    }
}

<#
.Description
Checks the running processes for Python and R scripts.
Exclues scripts with vscode in the path, such as the black formater.
Returns: true|false
#>
function Check-ScriptRunning {
    param (
        [string]$scriptType  # Accepts 'Python' or 'R'
    )

    switch ($scriptType.ToLower()) {
        'python' {
            $processName = 'python'
        }
        'r' {
            $processName = 'Rscript'
        }
        default {
            $msg = "Invalid script type. Please specify 'python' or 'r'."
            Write-Host $msg
            Write-Log -Message $msg
            return $false
        }
    }

    # Using WMI to get command-line details
    $processes = Get-WmiObject Win32_Process | Where-Object { $_.Name -like "$processName.exe" }

    if ($processes) {
        $filteredProcesses = $processes | Where-Object { $_.CommandLine -notlike '*vscode*' }

        if ($filteredProcesses) {
            $msg = "A $scriptType script is running."
            Write-Host $msg
            # Write-Log -Message $msg
            return $true
        }
    }

    $msg = "No $scriptType scripts are running."
    Write-Host $msg
    # Write-Log -Message $msg
    return $false
}

<#
.Description
Gets all logged-in users.
Exclues disconnected and idle users.
Gets the idle time of active users.
Convert idle time to seconds.
Finds the min idle time.
Returns: minumum idle time (in seconds) of active users, else null for no users | no active users
#>
function Get-MinIdleTimeInSecondsOfActiveUsers {
    # Get all logged-in users
    $sessions = quser 2>$null

    if ($sessions) {
        # Debug: Print the raw session output for reference
        # Write-Host "Raw session output:"
        # Write-Host $sessions

        $minIdleTimeInSeconds = [double]::MaxValue
        $sessions -split "`n" | ForEach-Object {
            # Match quser output format: Username, SessionName, SessionID, State, IdleTime, LogonTime
            if ($_ -match '^\s*(\S+)\s+(\S+)\s+(\d+)\s+(\w+)\s+(\S+)\s+(.+)$') {
                $username = $matches[1]
                $sessionName = $matches[2]
                $sessionID = $matches[3]
                $state = $matches[4]
                $idleTime = $matches[5]
                $logonTime = $matches[6]

                # Debug: Print the parsed user information
                # $msg = "User: $username, State: $state, IdleTime: $idleTime"
                # Write-Host $msg
                # Write-Log $msg

                # Check if the state is neither 'Disc' nor 'Idle'
                if ($state -ne 'Disc' -and $state -ne 'Idle') {
                    # Convert IdleTime to a TimeSpan and get total seconds
                    $timeSpan = Convert-IdleTimeToTimeSpan $idleTime
                    if ($timeSpan) {
                        $idleTimeInSeconds = $timeSpan.TotalSeconds

                        # Debug: Print the idle time in seconds
                        $msg = "Idle time (seconds) of user ${username}: ${idleTimeInSeconds}"
                        Write-Host $msg
                        # Write-Log $msg

                        # Find the minimum idle time
                        if ($idleTimeInSeconds -lt $minIdleTimeInSeconds) {
                            $minIdleTimeInSeconds = $idleTimeInSeconds
                        }
                    }
                }
            }
        }

        if ($minIdleTimeInSeconds -eq [double]::MaxValue) {
            $msg = "No active users found."
            Write-Host $msg
            Write-Log $msg
            return $null
        } else {
            $msg = "Minimum idle time (seconds) of active users: $minIdleTimeInSeconds"
            Write-Host $msg
            # Write-Log $msg
            return $minIdleTimeInSeconds
        }
    } else {
        $msg = "No users are logged in."
        Write-Host $msg
        Write-Log $msg
        return $null
    }
}

<#
.Description
 Helper function to convert idle time to TimeSpan
 Returns: TimeSpan
#>
function Convert-IdleTimeToTimeSpan {
    param (
        [string]$idleTime
    )

    try {
        # Handle "." which means zero idle time
        if ($idleTime -eq '.') {
            return New-TimeSpan -Minutes 0
        }

        # Match format like "1+23:45" (1 day, 23 hours, 45 minutes)
        if ($idleTime -match '(\d+)\+(\d+):(\d+)') {
            $days = [int]$matches[1]
            $hours = [int]$matches[2]
            $minutes = [int]$matches[3]
            return New-TimeSpan -Days $days -Hours $hours -Minutes $minutes
        }

        # Match format like "23:45" (23 hours, 45 minutes)
        elseif ($idleTime -match '(\d+):(\d+)') {
            $hours = [int]$matches[1]
            $minutes = [int]$matches[2]
            return New-TimeSpan -Hours $hours -Minutes $minutes
        }

        # Match integer-only format, like "45" (45 minutes)
        elseif ($idleTime -match '^\d+$') {
            $minutes = [int]$idleTime
            return New-TimeSpan -Minutes $minutes
        } else {
            $msg = "Unknown idle time format: $idleTime"
            Write-Host $msg
            Write-Log $msg
            return $null
        }
    } catch {
        $msg = "Failed to convert idle time: $idleTime"
        Write-Host $msg
        Write-Log $msg
        return $null
    }
}

<#
.Description
 Gets the system's current uptime, in seconds.
 Returns: uptime in seconds (int)
#>
function Get-SystemUptimeInSeconds {
    # Get the Last Boot Time
    $lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

    # Calculate the uptime in seconds
    $uptimeInSeconds = (New-TimeSpan -Start $lastBootTime).TotalSeconds
    $uptimeInSeconds = [math]::Round($uptimeInSeconds, 0)

    # Return the uptime in seconds
    $msg = "System uptime in seconds: $uptimeInSeconds"
    Write-Host $msg
    # Write-Log $msg
    return $uptimeInSeconds
}

$pythonRunning = Check-ScriptRunning -scriptType "Python"
$rRunning = Check-ScriptRunning -scriptType "R"
# Write-Host "Python running: $pythonRunning"
# Write-Host "R running: $rRunning"

$minIdleTimeInSeconds = Get-MinIdleTimeInSecondsOfActiveUsers
# Write-Host "Min idle time: $minIdleTimeInSeconds"

$uptimeInSeconds = Get-SystemUptimeInSeconds
# Write-Host "Uptime in seconds: $uptimeInSeconds"

# Are scritps running?
if ($pythonRunning -Or $rRunning) {
    # Yes=Do nothing
    $msg = "Are scritps running? Yes. Do nothing."
    Write-Host $msg
    Write-Log $msg
    Return
}
else {
    # Are scritps running=No
    $msg = "Are scritps running? No."
    Write-Host $msg
    Write-Log $msg
    # Is a user session active?
    if ($minIdleTimeInSeconds -eq $null) {
        # User session active=No
        $msg = "Is a user session active? No."
        Write-Host $msg
        Write-Log $msg
        # Did system boot >= 1 hour ago?
        if ($uptimeInSeconds -ge (60*60)) {
            # Yes=Shutdown
            $msg = "Did system boot >= 1 hour ago? Yes. Shutdown."
            Write-Host $msg
            Write-Log $msg
            Stop-Computer -Force
        }
        else {
            # No=Do nothing
            $msg = "Did system boot >= 1 hour ago? No. Do nothing."
            Write-Host $msg
            Write-Log $msg
            Return
        }
    }
    else {
        # User session active=Yes
        $msg = "Is a user session active? Yes."
        Write-Host $msg
        Write-Log $msg
        # Is min of last input >= 1 hour ago?
        if ($minIdleTimeInSeconds -ge (60*60)) {
            # Yes=Shutdown
            $msg = "Min of last input >= 1 hour ago? Yes. Shutdown."
            Write-Host $msg
            Write-Log $msg
            Stop-Computer -Force
        }
        else {
            # No=Do nothing
            $msg = "Min of last input >= 1 hour ago? No. Do nothing."
            Write-Host $msg
            Write-Log $msg
            Return
        }
    }
}