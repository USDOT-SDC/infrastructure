# GitLab Upgrade Script

Automates one-step-at-a-time GitLab EE upgrades on RHEL-based EC2 instances.
GitLab requires sequential version stops — this script determines the correct
next stop, verifies backups, performs the upgrade via SSH, and validates the
result.

## Prerequisites

- Python 3.x installed and on `PATH`
- AWS named profile configured with access to EC2 and S3 (read-only)
- SSH private key (`.pem`) for the GitLab EC2 instance
- Network access to the instance IP (VPN or bastion)

## Configuration

Edit `config.json` before running:

```json
{
    "ssh_key_path": "%UserProfile%\\.ssh\\your-key.pem",
    "ssh_user": "ec2-user",
    "aws_profile": "sdc-prod",
    "instance_id": "i-xxxxxxxxxxxxxxxxx",
    "ip_address": "10.x.x.x",
    "bucket": "prod-dot-sdc-gitlab-backup-xxxxxxxx"
}
```

| Field | Description |
|---|---|
| `ssh_key_path` | Path to the EC2 SSH private key. Supports `%UserProfile%` expansion. |
| `ssh_user` | SSH username on the EC2 instance (typically `ec2-user`). |
| `aws_profile` | AWS named profile to use for EC2/S3 API calls. |
| `instance_id` | EC2 instance ID of the GitLab server. |
| `ip_address` | Private IP address of the GitLab EC2 instance. |
| `bucket` | S3 bucket name where GitLab backups are stored. |

## How to Run

From the `scripts\gitlab-upgrade\` directory:

```cmd
setup_and_run.cmd
```

That's it. The script handles venv creation, dependency installation, and
launches `upgrade.py` automatically.

### What `setup_and_run.cmd` does

1. Creates a Python virtual environment (`.venv\`) if one does not exist
2. Activates the venv and upgrades `pip`
3. Installs dependencies from `requirements.txt`
4. Runs `upgrade.py`
5. Deactivates the venv on exit

## What the Upgrade Script Does

The script walks through six stages, prompting for confirmation at key
decision points.

### Stage 1 — Instance Check

Calls the EC2 API using the configured `aws_profile` to verify the GitLab
instance is in a `running` state. Aborts if the instance is stopped or
unavailable.

### Stage 2 — Backup Verification

Lists objects in the configured S3 bucket and finds the most recent:

- `*_gitlab_backup.tar` — full GitLab data backup
- `*gitlab-secrets.json` — GitLab secrets/tokens

Displays each file's name, size, and last-modified timestamp. If the backup
tar is older than 24 hours, you are asked whether to abort and create a
manual backup first. You must confirm before proceeding.

### Stage 3 — Get Current Version

SSH into the instance and runs several commands to detect the installed
GitLab EE version (e.g., `18.3.1`).

### Stage 4 — Determine Upgrade Path

Fetches GitLab's official upgrade path data and identifies all version stops
between the current version and the latest release. Displays the full path
and selects the **next required stop** as the upgrade target. GitLab does
not support skipping stops.

### Stage 5 — Perform Upgrade

Asks for a final confirmation, then runs three commands on the instance over
SSH:

1. `yum update -y --exclude=gitlab-ee` — patches system packages without
   pulling the latest GitLab
2. `yum install -y gitlab-ee-{target_version}` — installs the specific
   target version
3. `gitlab-ctl reconfigure` — applies configuration and database migrations
   (takes 5–10 minutes)

Output is streamed in real time so you can monitor progress.

### Stage 6 — Post-Upgrade Validation

Runs `gitlab-ctl status` over SSH and checks that all services are up.
Prints a reminder to manually verify the web UI:

1. Log in to an SDC workstation
2. Navigate to `https://gitlab.prod.sdc.dot.gov/`
3. Confirm the UI loads and the version in **Admin > Overview** matches
   the target

## Logs

Each run writes a log to `logs\` in this directory, named:

```text
logs\{from_version}_to_{to_version}_{timestamp}.log
```

Example: `logs\18.3.1_to_18.4.0_20260401_143000.log`

## Resume Capability

If the script is interrupted (network drop, Ctrl+C, etc.), a `status.json`
file records the last completed step. On the next run, the script detects
this file and offers to resume from where it left off rather than starting
over. Choosing not to resume clears the status and starts fresh.

## Running Successive Upgrades

Each run upgrades exactly **one version stop**. If the upgrade path shows
multiple stops between current and latest, re-run `setup_and_run.cmd` after
each successful upgrade until you reach the target version.
