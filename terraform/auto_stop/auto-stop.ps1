<#
.Description
Checks the running processes for Python and R scripts.
Exclues scripts with vscode in the path, such as the black formater.
Returns: true|false
#>
function Check-ScriptRunning {
    param (
        [string]$scriptType  # Accepts 'python' or 'r'
    )

    switch ($scriptType.ToLower()) {
        'python' {
            $processName = 'python'
        }
        'r' {
            $processName = 'Rscript'
        }
        default {
            Write-Host "Invalid script type. Please specify 'python' or 'r'."
            return $false
        }
    }

    # Using WMI to get command-line details
    $processes = Get-WmiObject Win32_Process | Where-Object { $_.Name -like "$processName.exe" }

    if ($processes) {
        $filteredProcesses = $processes | Where-Object { $_.CommandLine -notlike '*vscode*' }

        if ($filteredProcesses) {
            return $true
        }
    }

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
                # Write-Host "User: $username, SessionID: $sessionID, State: $state, IdleTime: $idleTime"

                # Check if the state is neither 'Disc' nor 'Idle'
                if ($state -ne 'Disc' -and $state -ne 'Idle') {
                    # Convert IdleTime to a TimeSpan and get total seconds
                    $timeSpan = Convert-IdleTimeToTimeSpan $idleTime
                    if ($timeSpan) {
                        $idleTimeInSeconds = $timeSpan.TotalSeconds

                        # Debug: Print the idle time in seconds
                        # Write-Host "Idle time (seconds) of user ${username}: ${idleTimeInSeconds}"

                        # Find the minimum idle time
                        if ($idleTimeInSeconds -lt $minIdleTimeInSeconds) {
                            $minIdleTimeInSeconds = $idleTimeInSeconds
                        }
                    }
                }
            }
        }

        if ($minIdleTimeInSeconds -eq [double]::MaxValue) {
            # Write-Host "No active users found."
            return $null
        } else {
            # Write-Host "Minimum idle time (seconds) of active users: $minIdleTimeInSeconds"
            return $minIdleTimeInSeconds
        }
    } else {
        # Write-Host "No users are logged in."
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

        if ($idleTime -match '(\d+)\+(\d+):(\d+)') {  # Match format like "1+23:45" (1 day, 23 hours, 45 minutes)
            $days = [int]$matches[1]
            $hours = [int]$matches[2]
            $minutes = [int]$matches[3]
            return New-TimeSpan -Days $days -Hours $hours -Minutes $minutes
        } elseif ($idleTime -match '(\d+):(\d+)') {  # Match format like "23:45" (23 hours, 45 minutes)
            $hours = [int]$matches[1]
            $minutes = [int]$matches[2]
            return New-TimeSpan -Hours $hours -Minutes $minutes
        } elseif ($idleTime -match '^\d+$') {  # Match format like "45" (45 minutes)
            return New-TimeSpan -Minutes [int]$idleTime
        } else {
            Write-Host "Unknown idle time format: $idleTime"
            return $null
        }
    } catch {
        Write-Host "Failed to convert idle time: $idleTime"
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

    # Return the uptime in seconds
    return [math]::Round($uptimeInSeconds, 0)
}

$pythonRunning = Check-ScriptRunning -scriptType "python"
$rRunning = Check-ScriptRunning -scriptType "r"
Write-Host "Python running: $pythonRunning"
Write-Host "R running: $rRunning"

$minIdleTimeInSeconds = Get-MinIdleTimeInSecondsOfActiveUsers
Write-Host "Min idle time: $minIdleTimeInSeconds"

$uptimeInSeconds = Get-SystemUptimeInSeconds
Write-Host "Uptime in seconds: $uptimeInSeconds"
