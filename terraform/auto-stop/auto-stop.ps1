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
        [string]$LogFilePath
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"

    $LogFilePath = Join-Path -Path $PSScriptRoot -ChildPath "auto-stop.log"
    
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
function Test-IsScriptRunning {
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
            # $msg = "A $scriptType script is running."
            # Write-Host $msg
            # Write-Log -Message $msg
            return $true
        }
    }

    # $msg = "No $scriptType scripts are running."
    # Write-Host $msg
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
                # $username = $matches[1]
                # $sessionName = $matches[2]
                # $sessionID = $matches[3]
                $state = $matches[4]
                $idleTime = $matches[5]
                # $logonTime = $matches[6]

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
                        # $msg = "Idle time (seconds) of user ${username}: ${idleTimeInSeconds}"
                        # Write-Host $msg
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
            # $msg = "No active users found."
            # Write-Host $msg
            # Write-Log $msg
            return $null
        }
        else {
            # $msg = "Minimum idle time (seconds) of active users: $minIdleTimeInSeconds"
            # Write-Host $msg
            # Write-Log $msg
            return $minIdleTimeInSeconds
        }
    }
    else {
        # $msg = "No users are logged in."
        # Write-Host $msg
        # Write-Log $msg
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
        }
        else {
            $msg = "Unknown idle time format: $idleTime"
            Write-Host $msg
            Write-Log $msg
            return $null
        }
    }
    catch {
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
    # $msg = "System uptime in seconds: $uptimeInSeconds"
    # Write-Host $msg
    # Write-Log $msg
    return $uptimeInSeconds
}

<#
.Description
 Gets the instance maintenance windows from DynamoDB
 Returns: Array of PS custom objects (items)
#>
function Get-MaintenanceWindows {
    param (
        [string]$TableName = 'instance_maintenance_windows',
        [string]$Region = 'us-east-1'
    )

    # Initialize variables for scanning the table
    $lastEvaluatedKey = $null
    $items = @()

    do {
        # Build the AWS CLI command
        $command = "aws dynamodb scan --table-name $TableName --region $Region"

        # Append the ExclusiveStartKey to handle pagination
        if ($lastEvaluatedKey) {
            $exclusiveStartKeyJson = $lastEvaluatedKey | ConvertTo-Json -Compress
            $command += " --exclusive-start-key '$exclusiveStartKeyJson'"
        }

        # Execute the AWS CLI command and capture the result
        $response = Invoke-Expression $command | ConvertFrom-Json

        # Append the items to the array
        $items += $response.Items

        # Check if there's more data to scan
        $lastEvaluatedKey = $response.LastEvaluatedKey

    } while ($lastEvaluatedKey)

    $instance_maintenance_windows = @()

    ForEach ($item in $items) {
        $instance_maintenance_windows += [pscustomobject]@{
            cron_expression = $item.cron_expression.S;
            duration        = $item.duration.S;
            timezone        = $item.timezone.S;
        }
    }

    return $instance_maintenance_windows
}

<#
.Description
 Test if the current datetime is within any instance maintenance window (active)
 Returns: true|false
#>
function Test-MaintenanceWindowActive {
    param (
        [Parameter(Mandatory = $true)]
        [Array]$MaintenanceWindows
    )

    # Get the current time in UTC
    $currentTimeUTC = [System.DateTime]::UtcNow
    
    foreach ($window in $MaintenanceWindows) {
        # Parse properties from the window object
        $cronExpression = $window.cron_expression
        $duration = [System.TimeSpan]::Parse($window.duration)

        # Create a hashtable to map timezone abbreviations to their respective timezone IDs
        $timezoneAbbreviationMap = @{
            "PST" = "Pacific Standard Time"
            "MST" = "Mountain Standard Time"
            "CST" = "Central Standard Time"
            "EST" = "Eastern Standard Time"
            "UTC" = "UTC"
            # Add more abbreviations as needed
        }

        $timezoneAbbreviation = $window.timezone
        # Check if the abbreviation exists in the hashtable
        if ($timezoneAbbreviationMap.ContainsKey($timezoneAbbreviation)) {
            # Get the corresponding timezone ID
            $timezone = $timezoneAbbreviationMap[$timezoneAbbreviation]
            
            # Retrieve the TimeZoneInfo object
            $timezoneInfo = [System.TimeZoneInfo]::FindSystemTimeZoneById($timezone)
        } else {
            $msg =  "The timezone abbreviation $timezoneAbbreviation is not recognized."
            Write-Host $msg
            Write-Log $msg
            continue
        }

        # Convert the current UTC time to the window's timezone
        $currentTimeInZone = [System.TimeZoneInfo]::ConvertTimeFromUtc($currentTimeUTC, $timezoneInfo)

        # Manually parse the cron expression
        $cronParts = $cronExpression -split ' '
        if ($cronParts.Length -ne 5) {
            $msg = "Invalid cron expression format: $cronExpression"
            Write-Host $msg
            Write-Log $msg
            continue
        }

        $minute = $cronParts[0]
        $hour = $cronParts[1]
        $dayOfWeek = $cronParts[4]

        # Check if the day of the week matches (Sunday=0, Monday=1, ..., Saturday=6)
        if ($dayOfWeek -ne '*' -and $currentTimeInZone.DayOfWeek -ne [int]$dayOfWeek) {
            continue  # Skip this window if the day doesn't match
        }

        # Adjust date format to match the system's output (dd-MM-yyyy HH:mm)
        $dateFormat = "dd-MM-yyyy HH:mm"
        $timeString = "$($currentTimeInZone.ToString('dd-MM-yyyy')) {0}:{1}" -f $hour.PadLeft(2, '0'), $minute.PadLeft(2, '0')

        try {
            $startTime = [datetime]::ParseExact($timeString, $dateFormat, [Globalization.CultureInfo]::InvariantCulture)
        }
        catch {
            $msg = "Failed to parse start time: $timeString"
            Write-Host $msg
            Write-Log $msg
            continue
        }

        # Calculate end time based on the duration
        $endTime = $startTime.Add($duration)

        # Check if current time falls within the maintenance window
        if ($currentTimeInZone -ge $startTime -and $currentTimeInZone -le $endTime) {
            # $msg = "A maintenance windows is active."
            # Write-Host $msg
            # Write-Log -Message $msg
            return $true
        }
    }

    # If no match found, return false
    # $msg = "No maintenance windows are active."
    # Write-Host $msg
    # Write-Log -Message $msg
    return $false
}

# === Get values for logic ===
$maintenanceWindows = Get-MaintenanceWindows
# Write-Host "MaintenanceWindows:"
# Write-Host $maintenanceWindows
$maintenanceWindowActive = Test-MaintenanceWindowActive -MaintenanceWindows $maintenanceWindows
# Write-Host "MaintenanceWindowActive: $maintenanceWindowActive"

$pythonRunning = Test-IsScriptRunning -scriptType "Python"
$rRunning = Test-IsScriptRunning -scriptType "R"
# Write-Host "Python running: $pythonRunning"
# Write-Host "R running: $rRunning"

$minIdleTimeInSeconds = Get-MinIdleTimeInSecondsOfActiveUsers
# Write-Host "Min idle time: $minIdleTimeInSeconds"

$uptimeInSeconds = Get-SystemUptimeInSeconds
# Write-Host "Uptime in seconds: $uptimeInSeconds"

# === Logic ===
# Maintenance window active?
if ($maintenanceWindowActive) {
    # Yes=Do nothing
    $msg = "Maintenance window active? Yes. === Do nothing ==="
    Write-Host $msg
    Write-Log $msg
    Return
}
else {
    # No
    $msg = "Maintenance window active? No."
    Write-Host $msg
    Write-Log $msg
}

# Are scritps running?
if ($pythonRunning -Or $rRunning) {
    # Yes=Do nothing
    $msg = "Are scritps running? Yes. === Do nothing ==="
    Write-Host $msg
    Write-Log $msg
    Return
}
else {
    # No
    $msg = "Are scritps running? No."
    Write-Host $msg
    Write-Log $msg
}

# Is a user session active?
if ($null -eq $minIdleTimeInSeconds) {
    # No
    $msg = "Is a user session active? No."
    Write-Host $msg
    Write-Log $msg
    # Did system boot >= 1 hour ago?
    if ($uptimeInSeconds -ge (60 * 60)) {
        # Yes=Shutdown
        $msg = "Did system boot >= 1 hour ago? Yes. === Shutdown ==="
        Write-Host $msg
        Write-Log $msg
        Stop-Computer -Force
    }
    else {
        # No=Do nothing
        $msg = "Did system boot >= 1 hour ago? No. === Do nothing ==="
        Write-Host $msg
        Write-Log $msg
        Return
    }
}
else {
    # Yes
    $msg = "Is a user session active? Yes."
    Write-Host $msg
    Write-Log $msg
    # Is min of last input >= 1 hour ago?
    if ($minIdleTimeInSeconds -ge (60 * 60)) {
        # Yes=Shutdown
        $msg = "Min of last input >= 1 hour ago? Yes. === Shutdown ==="
        Write-Host $msg
        Write-Log $msg
        Stop-Computer -Force
    }
    else {
        # No=Do nothing
        $msg = "Min of last input >= 1 hour ago? No. === Do nothing ==="
        Write-Host $msg
        Write-Log $msg
        Return
    }
}
