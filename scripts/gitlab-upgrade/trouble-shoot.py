#!/usr/bin/env python3
"""
GitLab post-upgrade troubleshooting script.

Connects to the GitLab EC2 instance via SSH and AWS APIs to collect
diagnostic information. All output is written to trouble-shoot.log
for review and analysis.
"""

import json
import logging
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import boto3
import paramiko
from botocore.exceptions import ClientError


# ---------------------------------------------------------------------------
# Logging — write to both console and logs/trouble-shoot_YYYYMMDD_HHMMSS.log
# ---------------------------------------------------------------------------
_logs_dir = Path("logs")
_logs_dir.mkdir(exist_ok=True)
LOG_PATH = _logs_dir / f"trouble-shoot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

_log_level = getattr(logging, os.environ.get("LOG_LEVEL", "INFO").upper(), logging.INFO)
logger = logging.getLogger()
logger.setLevel(_log_level)
for _h in logger.handlers[:]:
    logger.removeHandler(_h)

_ch = logging.StreamHandler()
_ch.setLevel(_log_level)
_ch.setFormatter(logging.Formatter("%(levelname)s - %(message)s"))
logger.addHandler(_ch)

_fh = logging.FileHandler(LOG_PATH, mode="a", encoding="utf-8")
_fh.setLevel(_log_level)
_fh.setFormatter(logging.Formatter("%(message)s"))
logger.addHandler(_fh)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def section(title: str) -> None:
    """Write a clearly delimited section header to the log."""
    bar = "=" * 72
    logger.info("")
    logger.info(bar)
    logger.info("  %s", title)
    logger.info(bar)


def subsection(title: str) -> None:
    """Write a subsection header."""
    logger.info("")
    logger.info("--- %s ---", title)


def log_result(label: str, value: str) -> None:
    """Write a labelled key/value result."""
    logger.info("  %-30s %s", label + ":", value)


def log_block(content: str, indent: int = 2) -> None:
    """Write a multi-line block with indentation, skipping blank lines at edges."""
    prefix = " " * indent
    lines = content.rstrip().splitlines()
    for line in lines:
        logger.info("%s%s", prefix, line)


# ---------------------------------------------------------------------------
# Main troubleshooter
# ---------------------------------------------------------------------------

class GitLabTroubleshooter:
    """Collects diagnostic data from a GitLab EC2 instance after a failed upgrade."""

    # Log files to tail — (label, remote path, lines)
    LOG_FILES: List[Tuple[str, str, int]] = [
        ("Reconfigure",        "/var/log/gitlab/reconfigure.log",                    80),
        ("Rails Production",   "/var/log/gitlab/gitlab-rails/production.log",        60),
        ("Rails Exceptions",   "/var/log/gitlab/gitlab-rails/exceptions_json.log",   30),
        ("Puma STDERR",        "/var/log/gitlab/puma/puma_stderr.log",               60),
        ("Puma Current",       "/var/log/gitlab/puma/current",                       60),
        ("Sidekiq Current",    "/var/log/gitlab/sidekiq/current",                    40),
        ("PostgreSQL Current", "/var/log/gitlab/postgresql/current",                 40),
        ("Redis Current",      "/var/log/gitlab/redis/current",                      30),
        ("Nginx Error",        "/var/log/gitlab/nginx/error.log",                    40),
        ("Nginx GitLab Error", "/var/log/gitlab/nginx/gitlab_error.log",             40),
        ("System Messages",    "/var/log/messages",                                  40),
    ]

    def __init__(self, config_path: str = "config.json") -> None:
        """
        Initialize the troubleshooter.

        Args:
            config_path: Path to config.json containing instance details.
        """
        self.config = self._load_config(config_path)
        os.environ["AWS_PROFILE"] = self.config["aws_profile"]

        self.ssh_client: Optional[paramiko.SSHClient] = None
        self.ec2: Any = boto3.client("ec2", region_name="us-east-1")
        self.s3: Any = boto3.client("s3", region_name="us-east-1")

    # ------------------------------------------------------------------
    # Config / SSH
    # ------------------------------------------------------------------

    def _load_config(self, config_path: str) -> Dict:
        """
        Load and validate configuration from JSON.

        Args:
            config_path: Path to the config file.

        Returns:
            Parsed configuration dict with expanded paths.

        Raises:
            ValueError: If a required key is missing.
        """
        with open(config_path, "r") as f:
            config = json.load(f)
        config["ssh_key_path"] = os.path.expandvars(config["ssh_key_path"])
        for key in ["instance_id", "ip_address", "ssh_key_path", "ssh_user", "aws_profile"]:
            if key not in config:
                raise ValueError(f"Missing required config key: {key}")
        return config

    def _connect_ssh(self, retries: int = 3) -> bool:
        """
        Establish (or re-establish) an SSH connection to the instance.

        Args:
            retries: Number of connection attempts before giving up.

        Returns:
            True if connection succeeded, False otherwise.
        """
        for attempt in range(retries):
            try:
                if self.ssh_client:
                    self.ssh_client.close()
                self.ssh_client = paramiko.SSHClient()
                self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                logger.info("  Connecting to %s (attempt %d/%d)...",
                            self.config["ip_address"], attempt + 1, retries)
                self.ssh_client.connect(
                    hostname=self.config["ip_address"],
                    username=self.config["ssh_user"],
                    key_filename=self.config["ssh_key_path"],
                    timeout=30,
                    banner_timeout=30,
                )
                transport = self.ssh_client.get_transport()
                if transport:
                    transport.set_keepalive(30)
                logger.info("  SSH connection established")
                return True
            except Exception as e:  # noqa: BLE001
                logger.warning("  SSH attempt %d failed: %s", attempt + 1, e)
        logger.error("  ERROR: Could not establish SSH connection after %d attempts", retries)
        return False

    def _ssh(self, command: str, timeout: int = 120) -> Tuple[int, str, str]:
        """
        Run a command on the remote instance.

        Args:
            command: Shell command to execute.
            timeout: Seconds to wait for the command to finish.

        Returns:
            Tuple of (exit_code, stdout, stderr).
        """
        if not self.ssh_client:
            if not self._connect_ssh():
                return (1, "", "No SSH connection")
        assert self.ssh_client is not None

        transport = self.ssh_client.get_transport()
        if not transport or not transport.is_active():
            if not self._connect_ssh():
                return (1, "", "No SSH connection")
        assert self.ssh_client is not None

        try:
            _, stdout, stderr = self.ssh_client.exec_command(command, timeout=timeout)
            stdout_str = stdout.read().decode("utf-8", errors="replace")
            stderr_str = stderr.read().decode("utf-8", errors="replace")
            exit_code = stdout.channel.recv_exit_status()
            return (exit_code, stdout_str, stderr_str)
        except Exception as e:  # noqa: BLE001
            return (1, "", str(e))

    # ------------------------------------------------------------------
    # AWS checks
    # ------------------------------------------------------------------

    def check_instance_state(self) -> None:
        """Check EC2 instance state and basic metadata via the AWS API."""
        section("AWS — EC2 Instance State")
        try:
            resp = self.ec2.describe_instances(InstanceIds=[self.config["instance_id"]])
            inst = resp["Reservations"][0]["Instances"][0]
            log_result("Instance ID",    inst.get("InstanceId", "unknown"))
            log_result("State",          inst["State"]["Name"])
            log_result("Instance Type",  inst.get("InstanceType", "unknown"))
            log_result("Launch Time",    str(inst.get("LaunchTime", "unknown")))
            log_result("Private IP",     inst.get("PrivateIpAddress", "unknown"))
            log_result("Image ID",       inst.get("ImageId", "unknown"))

            tags = {t["Key"]: t["Value"] for t in inst.get("Tags", [])}
            if tags:
                subsection("Tags")
                for k, v in tags.items():
                    log_result(k, v)

        except ClientError as e:
            logger.error("  ERROR: %s", e)

    def check_s3_backups(self) -> None:
        """List the most recent GitLab backups in S3."""
        section("AWS — S3 Backup Status")
        bucket = self.config.get("bucket", "")
        if not bucket:
            logger.warning("  No bucket configured — skipping backup check")
            return

        try:
            resp = self.s3.list_objects_v2(Bucket=bucket)
            if "Contents" not in resp:
                logger.warning("  No objects found in bucket: %s", bucket)
                return

            backup_tar = None
            secrets_json = None
            for obj in resp["Contents"]:
                key = obj.get("Key", "")
                lm = obj.get("LastModified")
                if key.endswith("_gitlab_backup.tar"):
                    if not backup_tar or (lm and backup_tar.get("LastModified") and lm > backup_tar["LastModified"]):
                        backup_tar = obj
                elif key.endswith("gitlab-secrets.json"):
                    if not secrets_json or (lm and secrets_json.get("LastModified") and lm > secrets_json["LastModified"]):
                        secrets_json = obj

            now = datetime.now(timezone.utc)

            for label, obj in [("Backup TAR", backup_tar), ("Secrets JSON", secrets_json)]:
                if obj:
                    age = now - obj["LastModified"] if obj.get("LastModified") else None
                    age_str = f"{age.days}d {age.seconds // 3600}h ago" if age else "unknown"
                    log_result(f"{label} key",  obj.get("Key", "unknown"))
                    log_result(f"{label} age",  age_str)
                    log_result(f"{label} size", f"{obj.get('Size', 0) / (1024**3):.2f} GB")
                else:
                    logger.warning("  %s: NOT FOUND", label)

        except ClientError as e:
            logger.error("  ERROR: %s", e)

    # ------------------------------------------------------------------
    # System checks (via SSH)
    # ------------------------------------------------------------------

    def check_system_resources(self) -> None:
        """Check disk space, memory, CPU load, and uptime."""
        section("System Resources")

        checks: List[Tuple[str, str]] = [
            ("Uptime / Load",  "uptime"),
            ("Disk Space",     "df -h --output=source,size,used,avail,pcent,target | grep -v tmpfs"),
            ("Memory",         "free -h"),
            ("CPU Count",      "nproc"),
            ("Top Processes",  "ps aux --sort=-%cpu | head -20"),
            ("OOM Killer Log", "sudo dmesg -T | grep -i 'oom\\|killed process' | tail -20"),
        ]

        for label, cmd in checks:
            subsection(label)
            rc, out, err = self._ssh(cmd)
            if out.strip():
                log_block(out)
            if err.strip() and rc != 0:
                logger.warning("  STDERR: %s", err.strip())

    def check_gitlab_version(self) -> None:
        """Detect what GitLab version is currently installed."""
        section("GitLab — Installed Version")

        cmds: List[Tuple[str, str]] = [
            ("RPM query",           "rpm -qa gitlab-ee"),
            ("Version manifest",    "sudo cat /opt/gitlab/version-manifest.txt | head -5"),
            ("gitlab-rake env",     "sudo gitlab-rake gitlab:env:info 2>&1 | grep -E 'GitLab|version'"),
        ]

        for label, cmd in cmds:
            subsection(label)
            rc, out, err = self._ssh(cmd, timeout=60)
            if out.strip():
                log_block(out)
            elif rc != 0:
                logger.info("  (no output — rc=%d)", rc)

    def check_gitlab_services(self) -> None:
        """Run gitlab-ctl status to see which services are up or down."""
        section("GitLab — Service Status (gitlab-ctl status)")
        rc, out, err = self._ssh("sudo gitlab-ctl status", timeout=60)
        if out.strip():
            log_block(out)
        if err.strip():
            log_block(err)
        if rc != 0:
            logger.warning("  WARNING: gitlab-ctl status exited with code %d", rc)

    def check_process_list(self) -> None:
        """Check whether key GitLab processes are running."""
        section("GitLab — Process Presence")

        processes: List[str] = ["puma", "sidekiq", "nginx", "postgres", "redis"]
        for proc in processes:
            _, out, _ = self._ssh(f"pgrep -a {proc} 2>/dev/null | head -5")
            if out.strip():
                log_result(proc, "RUNNING")
                log_block(out, indent=4)
            else:
                log_result(proc, "NOT FOUND")

    def check_network_ports(self) -> None:
        """Verify that GitLab is listening on expected ports (80, 443, 8080)."""
        section("Network — Listening Ports")
        _, out, _ = self._ssh("sudo ss -tlnp | grep -E ':(80|443|8080|8060)\\b'")
        if out.strip():
            log_block(out)
        else:
            logger.warning("  No GitLab ports (80/443/8080/8060) appear to be listening")

        # Also show full listening list for context
        subsection("All Listening TCP Ports")
        _, out, _ = self._ssh("sudo ss -tlnp")
        if out.strip():
            log_block(out)

    def check_health_endpoints(self) -> None:
        """Curl the GitLab health check endpoints from localhost on the instance."""
        section("GitLab — Health Endpoint Checks (from localhost)")

        endpoints: List[Tuple[str, str]] = [
            ("/-/health",       "curl -sf --max-time 10 -o /dev/null -w '%{http_code}' http://localhost/-/health"),
            ("/-/readiness",    "curl -sf --max-time 10 -o /dev/null -w '%{http_code}' http://localhost/-/readiness"),
            ("/-/liveness",     "curl -sf --max-time 10 -o /dev/null -w '%{http_code}' http://localhost/-/liveness"),
        ]

        for label, cmd in endpoints:
            rc, out, err = self._ssh(cmd, timeout=30)
            status = out.strip() if out.strip() else "(no response)"
            result = f"HTTP {status}" if status.isdigit() else status
            if rc != 0 and not out.strip():
                result = f"UNREACHABLE (rc={rc})"
            log_result(label, result)

        # Full JSON response from readiness for detail
        subsection("Readiness Detail (JSON)")
        _, out, _ = self._ssh(
            "curl -sf --max-time 10 http://localhost/-/readiness 2>&1 | python3 -m json.tool 2>/dev/null || "
            "curl -sf --max-time 10 http://localhost/-/readiness 2>&1",
            timeout=30,
        )
        if out.strip():
            log_block(out)
        else:
            logger.info("  (no response)")

    def check_database(self) -> None:
        """Check PostgreSQL service and pending migrations."""
        section("Database — PostgreSQL & Migrations")

        subsection("PostgreSQL Process")
        _, out, _ = self._ssh("sudo gitlab-ctl status postgresql 2>&1")
        log_block(out or "(no output)")

        subsection("Can Connect to DB")
        _, out, _ = self._ssh(
            "sudo gitlab-psql -c 'SELECT version();' 2>&1 | head -5",
            timeout=30,
        )
        log_block(out or "(no output)")

        subsection("Pending Migrations (last 30 lines)")
        logger.info("  Running db:migrate:status — this may take 30-60 seconds...")
        _, out, err = self._ssh(
            "sudo gitlab-rake db:migrate:status 2>&1 | tail -30",
            timeout=120,
        )
        log_block(out or "(no output)")
        if err.strip():
            log_block(err)

    def check_reconfigure_log(self) -> None:
        """Show the tail of the most recent reconfigure run."""
        section("GitLab — Last Reconfigure Output")
        rc, out, _ = self._ssh(
            "sudo tail -100 /var/log/gitlab/reconfigure.log 2>/dev/null || "
            "sudo journalctl -u gitlab-runsvdir --no-pager -n 100 2>/dev/null",
            timeout=30,
        )
        if out.strip():
            log_block(out)
        else:
            logger.info("  No reconfigure log found")

    def check_log_files(self) -> None:
        """Tail key GitLab and system log files for recent errors."""
        section("Log Files — Recent Entries")
        for label, path, lines in self.LOG_FILES:
            subsection(f"{label}  ({path})")
            rc, out, err = self._ssh(
                f"sudo tail -{lines} {path} 2>/dev/null",
                timeout=30,
            )
            if out.strip():
                log_block(out)
            else:
                logger.info("  (file not found or empty)")

    def check_yum_history(self) -> None:
        """Show recent yum transactions so we can confirm what was installed."""
        section("Package Manager — Recent yum Transactions")

        subsection("Last 5 Transactions")
        _, out, _ = self._ssh("sudo yum history list last 5 2>&1", timeout=30)
        log_block(out or "(no output)")

        subsection("Last Transaction Info (gitlab-ee)")
        _, out, _ = self._ssh(
            "sudo yum history info last 2>&1 | grep -E 'gitlab|Install|Update|Error' | head -30",
            timeout=30,
        )
        log_block(out or "(no output)")

    def check_selinux_and_firewall(self) -> None:
        """Check SELinux status and firewall rules that might block GitLab."""
        section("SELinux & Firewall")

        subsection("SELinux Status")
        _, out, _ = self._ssh("getenforce 2>/dev/null || sestatus 2>/dev/null || echo 'SELinux tools not found'")
        log_block(out or "(no output)")

        subsection("Recent SELinux Denials (last 20)")
        _, out, _ = self._ssh("sudo ausearch -m avc -ts recent 2>&1 | tail -20")
        log_block(out or "(no output — may mean no denials or auditd not running)")

        subsection("Firewall Rules (firewalld)")
        _, out, _ = self._ssh("sudo firewall-cmd --list-all 2>/dev/null || sudo iptables -L -n 2>/dev/null | head -40")
        log_block(out or "(no output)")

    def check_gitlab_config(self) -> None:
        """Show non-secret relevant lines from gitlab.rb."""
        section("GitLab — Configuration Snapshot (gitlab.rb, non-secret lines)")
        _, out, _ = self._ssh(
            "sudo grep -v -E \"#|password|secret|token|private_key|^$\" "
            "/etc/gitlab/gitlab.rb 2>/dev/null | head -60",
            timeout=30,
        )
        log_block(out or "(no output or file not found)")

    # ------------------------------------------------------------------
    # Orchestration
    # ------------------------------------------------------------------

    def run(self) -> int:
        """
        Run all diagnostic checks and write results to trouble-shoot.log.

        Returns:
            0 on completion (partial failures are logged, not fatal).
        """
        start = datetime.now()

        logger.info("=" * 72)
        logger.info("  GitLab Troubleshooter")
        logger.info("  Started: %s", start.strftime("%Y-%m-%d %H:%M:%S"))
        logger.info("  Instance: %s  (%s)", self.config["instance_id"], self.config["ip_address"])
        logger.info("  AWS Profile: %s", self.config["aws_profile"])
        logger.info("  Log: %s", LOG_PATH)
        logger.info("=" * 72)

        try:
            # AWS-level (no SSH needed)
            self.check_instance_state()
            self.check_s3_backups()

            # All remaining checks need SSH
            if not self._connect_ssh():
                logger.error("")
                logger.error("FATAL: Cannot SSH to instance — AWS and backup checks logged above.")
                logger.error("Verify the instance is running, your VPN/network is up, and the key path is correct.")
                return 1

            self.check_system_resources()
            self.check_gitlab_version()
            self.check_gitlab_services()
            self.check_process_list()
            self.check_network_ports()
            self.check_health_endpoints()
            self.check_database()
            self.check_reconfigure_log()
            self.check_log_files()
            self.check_yum_history()
            self.check_selinux_and_firewall()
            self.check_gitlab_config()

        except KeyboardInterrupt:
            logger.info("\nInterrupted by user")
        except Exception as e:  # noqa: BLE001
            import traceback
            logger.error("FATAL: %s\n%s", e, traceback.format_exc())
        finally:
            if self.ssh_client:
                self.ssh_client.close()

        elapsed = datetime.now() - start
        section("Done")
        logger.info("  Elapsed: %s", elapsed)
        logger.info("  Output written to: %s", LOG_PATH)
        logger.info("")

        return 0


def main() -> None:
    """Entry point."""
    upgrader = GitLabTroubleshooter()
    sys.exit(upgrader.run())


if __name__ == "__main__":
    main()
