#!/usr/bin/env bash
#
# Auto-Stop Script for RHEL 8/9 EC2 Instances (v1.1.0)
# Checks Maintenance Windows (DynamoDB), Running Scripts (Python/R),
# System Patching Activity, Active User Idle Times, and System Uptime
# before initiating shutdown.
# Set DRY_RUN to "false" for real deployment.


# Ensure aws/python3 etc. are found even under a minimal cron PATH.
export PATH="/usr/local/aws-cli/v2/current/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# ==========================================
# Configuration
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/auto-stop.log"
STATE_FILE="${SCRIPT_DIR}/.autostop_last_active"
DYNAMODB_TABLE="instance_maintenance_windows"
AWS_REGION="us-east-1"
IDLE_THRESHOLD_SEC=3600 # 1 hour

# Set to "true" to log what the script would do without actually shutting
# down the instance. Useful for testing on a live instance you don't want
# to lose. Set back to "false" for real deployment.
DRY_RUN="true"

# Wraps the actual shutdown call so DRY_RUN only needs to be checked here.
do_shutdown() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        write_log "DRY RUN: shutdown conditions met, this is when I would be shutting down."
    else
        /sbin/shutdown -h now
    fi
}

# ==========================================
# Logging
# ==========================================
write_log() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_entry="${timestamp} - ${message}"

    echo "${log_entry}"
    echo "${log_entry}" >> "${LOG_FILE}" 2>/dev/null || {
        echo "Failed to write to log file: ${LOG_FILE}" >&2
    }
}

# ==========================================
# Lock-file check (no lsof dependency)
# ==========================================
test_lock_held() {
    local lock_path="$1"
    [[ -e "$lock_path" ]] || return 1

    local fd
    for fd in /proc/[0-9]*/fd/*; do
        [[ -L "$fd" ]] || continue
        if [[ "$(readlink -f "$fd" 2>/dev/null)" == "$lock_path" ]]; then
            return 0
        fi
    done

    return 1
}

# ==========================================
# Patching check 
# (process names + lock files, includes rpm/packagekitd)
# ==========================================
test_is_patching_active() {
    if pgrep -x "dnf" >/dev/null || pgrep -x "yum" >/dev/null \
        || pgrep -x "rpm" >/dev/null || pgrep -x "packagekitd" >/dev/null; then
        return 0
    fi

    if test_lock_held "/var/lib/dnf/lock" || test_lock_held "/var/run/dnf.lock"; then
        return 0
    fi

    return 1
}

# ==========================================
# Script-activity check (loginuid filtering: filters to real human logins
# so system daemons/services running python under a service account don't
# block shutdown, even when invoked via sudo/su). Presence of a matching,
# human-attributed process is treated as "running" - we deliberately do NOT
# gate on a short CPU-sampling window here: a real user script can be
# legitimately idle on I/O (disk, network, a DB query, a sleep/wait) at the
# instant we sample it, and a false negative in this check risks killing a
# real unattended job, which is a worse failure mode than the false positive
# (e.g. an idle editor language-server process) it would guard against.
# Checks Python and R together in a single pass.
# ==========================================
test_is_script_running() {
    local running_pids
    running_pids=$(pgrep -f -i "python|Rscript|exec/R" 2>/dev/null)

    if [[ -z "${running_pids}" ]]; then
        return 1
    fi

    for pid in ${running_pids}; do
        # Skip this script's own PID/parent PID.
        if [[ "${pid}" -eq "$$" || "${pid}" -eq "$PPID" ]]; then
            continue
        fi

        local cmdline
        cmdline=$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null)
        [[ -z "${cmdline}" ]] && continue

        # Skip this script's own inline invocations.
        if [[ "${cmdline}" =~ auto-stop ]]; then
            continue
        fi

        # Original login UID survives sudo/su, so a human who ran
        # `sudo python3 script.py` is still correctly identified as human.
        # Sentinel 4294967295 = no login session (systemd/cron/container).
        local loginuid
        loginuid=$(cat "/proc/${pid}/loginuid" 2>/dev/null)

        if [[ -z "${loginuid}" || "${loginuid}" == "4294967295" || "${loginuid}" -lt 1000 ]]; then
            continue
        fi

        write_log "Active user script detected: PID ${pid} (loginuid ${loginuid}) - ${cmdline}"
        return 0
    done

    return 1
}

# ==========================================
# Idle-time check (explicit '?' detection with a warning 
# instead of silently dropping it, and a safeguard so an all-'?'
# result doesn't fall through to a bogus huge idle value)
# ==========================================
get_min_idle_time_seconds() {
    local min_idle=99999999
    local user_found=0
    local known_idle_found=0

    # Use `w -hs` (short format: USER TTY IDLE WHAT) instead of the default
    # 8-column format. The default format's FROM column is blank for local
    # console/pts sessions with no remote host, which silently shifts every
    # column left by one and makes a fixed field number for IDLE unreliable.
    # Short format drops FROM/LOGIN@/JCPU/PCPU entirely, so IDLE is always
    # field 3, regardless of whether FROM would have been populated.
    while read -r idle_str; do
        [[ -z "$idle_str" ]] && continue
        user_found=1

        if [[ "$idle_str" == "?" ]]; then
            write_log "WARN: Unable to determine idle time for a session (w reported '?'). Skipping it in idle calculation."
            continue
        fi

        known_idle_found=1
        local idle_sec=0

        if [[ "$idle_str" =~ ([0-9]+):([0-9]+)m ]]; then
            idle_sec=$(( 10#${BASH_REMATCH[1]} * 3600 + 10#${BASH_REMATCH[2]} * 60 ))
        elif [[ "$idle_str" =~ ([0-9]+):([0-9]+) ]]; then
            idle_sec=$(( 10#${BASH_REMATCH[1]} * 60 + 10#${BASH_REMATCH[2]} ))
        elif [[ "$idle_str" =~ ([0-9]+)\.([0-9]+)s ]]; then
            idle_sec=${BASH_REMATCH[1]}
        elif [[ "$idle_str" =~ ([0-9]+)days? ]]; then
            idle_sec=$(( ${BASH_REMATCH[1]} * 86400 ))
        else
            write_log "WARN: Unrecognized idle time format '${idle_str}' from w. Treating session as active (0s idle)."
            idle_sec=0
        fi

        if (( idle_sec < min_idle )); then
            min_idle=$idle_sec
        fi
    done < <(w -hs | awk '{print $3}')

    if [[ $user_found -eq 1 && $known_idle_found -eq 0 ]]; then
        echo "0"
    elif [[ $user_found -eq 1 ]]; then
        echo "$min_idle"
    else
        echo "null"
    fi
}

get_system_uptime_seconds() {
    awk '{print int($1)}' /proc/uptime
}

# ==========================================
# Execution-context logging (includes diagnostics: who/what identity
# this script is running as, useful for debugging AWS access issues).
# Covers IMDSv2 (token-based) request in case IMDSv1 may be disabled.
# ==========================================
log_execution_context() {
    local os_user
    os_user=$(whoami 2>/dev/null || echo "unknown")

    local imds_token
    imds_token=$(curl -s -m 2 -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null)

    local instance_id
    if [[ -n "${imds_token}" ]]; then
        instance_id=$(curl -s -m 2 -H "X-aws-ec2-metadata-token: ${imds_token}" \
            http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
    else
        instance_id=$(curl -s -m 2 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
    fi
    instance_id="${instance_id:-unknown}"

    write_log "Running as OS user: ${os_user} | Instance ID: ${instance_id}"

    local identity
    identity=$(aws sts get-caller-identity --output json 2>&1)
    local identity_rc=$?

    if [[ ${identity_rc} -eq 0 ]]; then
        local account arn
        read -r account arn <<< "$(echo "${identity}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('Account','unknown'), d.get('Arn','unknown'))
" 2>/dev/null)"
        write_log "AWS identity resolved OK | Account: ${account} | ARN: ${arn}"
    else
        write_log "ERROR: 'aws sts get-caller-identity' failed (exit code ${identity_rc}). No usable AWS credentials found for user '${os_user}'. Details: ${identity}"
    fi
}

# ==========================================
# Maintenance-window check (Python/zoneinfo cron matching plus detailed scan diagnostics
# also retains return-code convention so main logic stays consistent with the rest of the script)
# ==========================================
test_maintenance_window_active() {
    if ! command -v aws &> /dev/null; then
        write_log "AWS CLI not found. Skipping maintenance window check."
        return 1
    fi
    if ! command -v python3 &> /dev/null; then
        write_log "python3 not found. Skipping maintenance window check."
        return 1
    fi

    log_execution_context

    local aws_err response aws_rc aws_stderr
    aws_err=$(mktemp)
    response=$(aws dynamodb scan --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" --output json 2>"${aws_err}")
    aws_rc=$?
    aws_stderr=$(<"${aws_err}")
    rm -f "${aws_err}"

    if [[ ${aws_rc} -ne 0 ]]; then
        write_log "ERROR: 'aws dynamodb scan' failed (exit code ${aws_rc}) on table '${DYNAMODB_TABLE}' in region '${AWS_REGION}'. AWS CLI error: ${aws_stderr}"
        return 1
    fi

    if [[ -z "${response}" ]]; then
        write_log "Warning: DynamoDB scan on table '${DYNAMODB_TABLE}' (region '${AWS_REGION}') returned no data, but exited successfully. Table may be empty."
        return 1
    fi

    local item_count
    item_count=$(echo "${response}" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('Items', [])))" 2>/dev/null)
    write_log "DynamoDB scan succeeded on table '${DYNAMODB_TABLE}'. Items returned: ${item_count:-unknown}"

    local py_err py_rc is_active
    py_err=$(mktemp)
    is_active=$(echo "${response}" | python3 -c "
import sys, json, datetime

try:
    import zoneinfo
except ImportError as e:
    print(f'FATAL: zoneinfo unavailable (python {sys.version.split()[0]}): {e}', file=sys.stderr)
    print(f'FATAL: this python has no zoneinfo module and no backports.zoneinfo fallback installed', file=sys.stderr)
    print('false')
    sys.exit(0)

data = json.load(sys.stdin)
items = data.get('Items', [])
print(f'DEBUG: evaluating {len(items)} maintenance-window item(s)', file=sys.stderr)


# Fixed UTC offsets (not DST-aware IANA zones): the maintenance-window
# records store these abbreviations to mean a constant offset from UTC
# year-round (e.g. 'EST' always means UTC-5), not \"Eastern local time,
# whichever DST status currently applies\". Etc/GMT+N zone names use the
# POSIX-inverted sign convention, so GMT+5 is UTC-5, GMT+4 is UTC-4, etc.
tz_map = {
    'PST': 'Etc/GMT+8', 'PDT': 'Etc/GMT+7',
    'MST': 'Etc/GMT+7', 'MDT': 'Etc/GMT+6',
    'CST': 'Etc/GMT+6', 'CDT': 'Etc/GMT+5',
    'EST': 'Etc/GMT+5', 'EDT': 'Etc/GMT+4',
    'UTC': 'UTC'
}

now_utc = datetime.datetime.now(datetime.timezone.utc)
active = False

for idx, item in enumerate(items):
    cron_expr = item.get('cron_expression', {}).get('S', '')
    duration_str = item.get('duration', {}).get('S', '00:00:00')
    tz_abbr = item.get('timezone', {}).get('S', 'UTC')
    tag = f'item[{idx}] cron=\"{cron_expr}\" duration={duration_str} tz={tz_abbr}'

    tz_name = tz_map.get(tz_abbr, 'UTC')
    try:
        tz = zoneinfo.ZoneInfo(tz_name)
    except Exception as e:
        print(f'{tag}: SKIP - bad timezone \"{tz_name}\": {e}', file=sys.stderr)
        continue

    now_tz = now_utc.astimezone(tz)

    parts = cron_expr.split()
    if len(parts) != 5:
        print(f'{tag}: SKIP - cron_expression does not have 5 fields (got {len(parts)}: {parts!r})', file=sys.stderr)
        continue
    minute_spec, hour_spec, _, _, dow_spec = parts

    python_dow = (now_tz.weekday() + 1) % 7  # convert to cron's 0=Sunday
    try:
        if dow_spec != '*' and int(dow_spec) != python_dow:
            print(f'{tag}: no match - day-of-week {dow_spec} != today ({python_dow}) in {tz_name}', file=sys.stderr)
            continue
    except ValueError:
        print(f'{tag}: SKIP - day-of-week field \"{dow_spec}\" is not \"*\" or an integer', file=sys.stderr)
        continue

    try:
        start_time = now_tz.replace(hour=int(hour_spec), minute=int(minute_spec), second=0, microsecond=0)
    except ValueError as e:
        print(f'{tag}: SKIP - invalid hour/minute \"{hour_spec}:{minute_spec}\": {e}', file=sys.stderr)
        continue

    # duration is stored as either HH:MM:SS or HH:MM (seconds omitted, treated as :00)
    duration_parts = duration_str.split(':')
    try:
        if len(duration_parts) == 3:
            h, m, s = map(int, duration_parts)
        elif len(duration_parts) == 2:
            h, m = map(int, duration_parts)
            s = 0
        else:
            raise ValueError(f'expected 2 or 3 colon-separated fields, got {len(duration_parts)}')
    except ValueError as e:
        print(f'{tag}: SKIP - duration \"{duration_str}\" is not HH:MM or HH:MM:SS: {e}', file=sys.stderr)
        continue
    end_time = start_time + datetime.timedelta(hours=h, minutes=m, seconds=s)

    if start_time <= now_tz <= end_time:
        print(f'{tag}: MATCH - window {start_time} to {end_time} ({tz_name}) contains now ({now_tz})', file=sys.stderr)
        active = True
        break
    else:
        print(f'{tag}: no match - window {start_time} to {end_time} ({tz_name}) does not contain now ({now_tz})', file=sys.stderr)

print('true' if active else 'false')
" 2>"${py_err}")
    py_rc=$?
    if [[ -s "${py_err}" ]]; then
        write_log "Maintenance-window matcher diagnostics: $(<"${py_err}")"
    fi
    rm -f "${py_err}"

    if [[ ${py_rc} -ne 0 ]]; then
        write_log "ERROR: maintenance-window matcher (python3) exited with code ${py_rc}. Treating as no active window."
        return 1
    fi

    if [[ "${is_active}" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# ==========================================
# Main Logic
# ==========================================

# 1. Maintenance Window Check
if test_maintenance_window_active; then
    write_log "Maintenance window active? Yes. === Do nothing ==="
    exit 0
else
    write_log "Maintenance window active? No."
fi

# 2. System Patching Activity
if test_is_patching_active; then
    write_log "System patching / DNF active? Yes. === Do nothing ==="
    exit 0
else
    write_log "System patching / DNF active? No."
fi

# 3. Running User/Admin Scripts (Python or R, single pass)
if test_is_script_running; then
    write_log "Are scripts running? Yes. === Do nothing ==="
    exit 0
else
    write_log "Are scripts running? No."
fi

# 4. Active User Sessions and Idle Time
#
# When no login session exists (e.g. right after logout), we cannot measure
# idle time via `w`. Falling back to raw system uptime is wrong here: if the
# instance has been up for a while before the user logged out, uptime is
# already past the threshold and the very next run would shut down
# immediately - nowhere near a full hour of actual inactivity.
#
# Instead we persist the last known "user was active" timestamp to
# STATE_FILE: (now - min_idle_time) whenever a session is present. Once the
# session disappears, elapsed time is measured from that recorded timestamp,
# not from boot. STATE_FILE only falls back to boot time on the very first
# run ever (no prior record), which is the correct behavior for an instance
# that has never had anyone log in.
now_epoch=$(date +%s)
uptime_seconds=$(get_system_uptime_seconds)
min_idle_time=$(get_min_idle_time_seconds)

if [[ "$min_idle_time" == "null" ]]; then
    write_log "Is a user session active? No."

    last_active_epoch=""
    if [[ -f "$STATE_FILE" ]]; then
        last_active_epoch=$(<"$STATE_FILE")
    fi

    if [[ -z "$last_active_epoch" || ! "$last_active_epoch" =~ ^[0-9]+$ ]]; then
        last_active_epoch=$(( now_epoch - uptime_seconds ))
        write_log "No prior activity record in ${STATE_FILE}. Using system boot time as baseline."
    fi

    seconds_since_active=$(( now_epoch - last_active_epoch ))
    write_log "Seconds since last known user activity: ${seconds_since_active}."

    if (( seconds_since_active >= IDLE_THRESHOLD_SEC )); then
        write_log "Idle with no session for >= 1 hour? Yes. === Shutdown ==="
        # /sbin/shutdown -h now
        do_shutdown
    else
        write_log "Idle with no session for >= 1 hour? No. === Do nothing ==="
        exit 0
    fi
else
    write_log "Is a user session active? Yes."

    # Record the actual last-input moment so that if the session ends before
    # the next run, elapsed time is measured from real user activity.
    echo $(( now_epoch - min_idle_time )) > "$STATE_FILE" 2>/dev/null

    if (( min_idle_time >= IDLE_THRESHOLD_SEC )); then
        write_log "Min of last input >= 1 hour ago? Yes. === Shutdown ==="
        # /sbin/shutdown -h now
        do_shutdown
    else
        write_log "Min of last input >= 1 hour ago? No. === Do nothing ==="
        exit 0
    fi
fi
