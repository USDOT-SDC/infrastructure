#!/usr/bin/env python3
"""
GitLab service status checker and manager.

Connects to the GitLab EC2 instance via SSH and reports service status.
Optionally starts stopped services, restarts all services, or runs reconfigure.

Usage:
    python status-gitlab.py                          # status only
    python status-gitlab.py --start                  # start any 'normally up' services that are down
    python status-gitlab.py --restart                # restart all services
    python status-gitlab.py --restart --service puma nginx   # restart specific services
    python status-gitlab.py --reconfigure            # run gitlab-ctl reconfigure
    python status-gitlab.py --watch                  # re-check every 10s until all services are up
    python status-gitlab.py --watch 30               # re-check every 30s
    python status-gitlab.py --tail puma              # tail logs for one or more services
    python status-gitlab.py --start --tail           # start downed services then tail their logs
"""

import argparse
import json
import logging
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import paramiko


# ---------------------------------------------------------------------------
# Logging — console + logs/status-gitlab_YYYYMMDD_HHMMSS.log
# ---------------------------------------------------------------------------
import datetime as _dt
_logs_dir = Path("logs")
_logs_dir.mkdir(exist_ok=True)
LOG_PATH = _logs_dir / f"status-gitlab_{_dt.datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

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
# Data model
# ---------------------------------------------------------------------------

@dataclass
class ServiceInfo:
    """Represents one GitLab runit service."""

    name: str
    state: str           # "run" | "down" | "unknown"
    pid: Optional[int]
    uptime_s: Optional[int]
    normally_up: bool    # True if runit says "normally up"
    raw: str             # original status line

    @property
    def is_up(self) -> bool:
        """Return True if the service is running."""
        return self.state == "run"

    @property
    def uptime_human(self) -> str:
        """Return uptime as a human-readable string."""
        if self.uptime_s is None:
            return "?"
        h, remainder = divmod(self.uptime_s, 3600)
        m, s = divmod(remainder, 60)
        if h:
            return f"{h}h {m}m {s}s"
        if m:
            return f"{m}m {s}s"
        return f"{s}s"


# ---------------------------------------------------------------------------
# Parser for `gitlab-ctl status` output
# ---------------------------------------------------------------------------

_STATUS_RE = re.compile(
    r"^(?P<state>run|down):\s+(?P<name>[\w-]+):\s+"
    r"(?:\(pid\s+(?P<pid>\d+)\)\s+)?(?P<uptime>\d+)s"
    r"(?P<normally>,\s*normally up)?"
)


def parse_status(output: str) -> List[ServiceInfo]:
    """
    Parse output of ``gitlab-ctl status`` into a list of ServiceInfo objects.

    Args:
        output: Raw stdout from ``gitlab-ctl status``.

    Returns:
        List of parsed ServiceInfo objects, sorted by name.
    """
    services: List[ServiceInfo] = []
    for line in output.splitlines():
        line = line.strip()
        m = _STATUS_RE.match(line)
        if not m:
            continue
        services.append(ServiceInfo(
            name=m.group("name"),
            state=m.group("state"),
            pid=int(m.group("pid")) if m.group("pid") else None,
            uptime_s=int(m.group("uptime")),
            normally_up=bool(m.group("normally")),
            raw=line,
        ))
    return sorted(services, key=lambda s: s.name)


# ---------------------------------------------------------------------------
# Main class
# ---------------------------------------------------------------------------

class GitLabServiceManager:
    """SSH-based GitLab service status checker and manager."""

    def __init__(self, config_path: str = "config.json") -> None:
        """
        Initialize with config.json.

        Args:
            config_path: Path to JSON config containing instance details.

        Raises:
            ValueError: If a required config key is missing.
            FileNotFoundError: If config_path does not exist.
        """
        with open(config_path, "r") as f:
            config: Dict = json.load(f)
        config["ssh_key_path"] = os.path.expandvars(config["ssh_key_path"])
        for key in ["instance_id", "ip_address", "ssh_key_path", "ssh_user"]:
            if key not in config:
                raise ValueError(f"Missing required config key: {key}")
        self.config = config
        self.ssh_client: Optional[paramiko.SSHClient] = None

    # ------------------------------------------------------------------
    # SSH helpers
    # ------------------------------------------------------------------

    def connect(self, retries: int = 3) -> bool:
        """
        Establish SSH connection with retry logic.

        Args:
            retries: Number of attempts before giving up.

        Returns:
            True if connected, False otherwise.
        """
        for attempt in range(retries):
            try:
                if self.ssh_client:
                    self.ssh_client.close()
                self.ssh_client = paramiko.SSHClient()
                self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
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
                return True
            except Exception as e:  # noqa: BLE001
                logger.warning("SSH attempt %d/%d failed: %s", attempt + 1, retries, e)
                if attempt < retries - 1:
                    time.sleep(3)
        logger.error("Could not establish SSH connection to %s", self.config["ip_address"])
        return False

    def _run(self, command: str, timeout: int = 120, stream: bool = False) -> Tuple[int, str, str]:
        """
        Execute a command over SSH.

        Args:
            command: Shell command to run.
            timeout: Seconds before timing out.
            stream:  If True, print stdout lines in real time via logger.

        Returns:
            Tuple of (exit_code, stdout, stderr).
        """
        assert self.ssh_client is not None, "Call connect() first"

        transport = self.ssh_client.get_transport()
        if not transport or not transport.is_active():
            if not self.connect():
                return (1, "", "SSH disconnected and reconnect failed")

        try:
            _, stdout, stderr = self.ssh_client.exec_command(command, timeout=timeout)

            if stream:
                stdout_lines: List[str] = []
                while not stdout.channel.exit_status_ready():
                    if stdout.channel.recv_ready():
                        chunk = stdout.channel.recv(4096).decode("utf-8", errors="replace")
                        for line in chunk.splitlines():
                            logger.info("  %s", line)
                            stdout_lines.append(line)
                    time.sleep(0.1)
                remainder = stdout.read().decode("utf-8", errors="replace")
                for line in remainder.splitlines():
                    logger.info("  %s", line)
                    stdout_lines.append(line)
                exit_code = stdout.channel.recv_exit_status()
                return (exit_code, "\n".join(stdout_lines), stderr.read().decode("utf-8", errors="replace"))

            out = stdout.read().decode("utf-8", errors="replace")
            err = stderr.read().decode("utf-8", errors="replace")
            return (stdout.channel.recv_exit_status(), out, err)

        except Exception as e:  # noqa: BLE001
            return (1, "", str(e))

    def disconnect(self) -> None:
        """Close the SSH connection."""
        if self.ssh_client:
            self.ssh_client.close()

    # ------------------------------------------------------------------
    # Service operations
    # ------------------------------------------------------------------

    def get_status(self) -> List[ServiceInfo]:
        """
        Fetch and parse current GitLab service status.

        Returns:
            Parsed list of ServiceInfo objects, sorted by name.
        """
        _, out, _ = self._run("sudo gitlab-ctl status", timeout=30)
        return parse_status(out)

    def print_status_table(self, services: List[ServiceInfo]) -> None:
        """
        Print a formatted status table.

        Args:
            services: List of ServiceInfo to display.
        """
        up   = [s for s in services if s.is_up]
        down = [s for s in services if not s.is_up]

        logger.info("")
        logger.info("  %-22s  %-6s  %-12s  %s", "SERVICE", "STATE", "UPTIME", "PID")
        logger.info("  " + "-" * 58)
        for s in up:
            logger.info("  %-22s  %-6s  %-12s  %s", s.name, "UP", s.uptime_human, s.pid or "")
        for s in down:
            flag = "  (normally up)" if s.normally_up else ""
            logger.info("  %-22s  %-6s  %-12s%s", s.name, "DOWN", s.uptime_human, flag)
        logger.info("")
        logger.info("  Summary: %d up, %d down", len(up), len(down))

    def start_services(self, services: List[ServiceInfo], targets: Optional[List[str]] = None) -> List[str]:
        """
        Start services that are down.

        If targets is None, starts all services marked "normally up" that are down.
        If targets is provided, starts only those named services regardless of
        their normally_up flag.

        Args:
            services: Current service list from get_status().
            targets:  Optional explicit list of service names to start.

        Returns:
            Names of services that were successfully started.
        """
        if targets:
            to_start = [s for s in services if not s.is_up and s.name in targets]
        else:
            to_start = [s for s in services if not s.is_up and s.normally_up]

        if not to_start:
            logger.info("  No services need starting.")
            return []

        started: List[str] = []
        for s in to_start:
            logger.info("  Starting %-20s ...", s.name)
            rc, out, err = self._run(f"sudo gitlab-ctl start {s.name}", timeout=60)
            if rc == 0:
                logger.info("    OK")
                started.append(s.name)
            else:
                logger.warning("    FAILED (rc=%d)  %s", rc, (err or out).strip())
        return started

    def restart_services(self, services: List[ServiceInfo], targets: Optional[List[str]] = None) -> None:
        """
        Restart services.

        Args:
            services: Current service list from get_status().
            targets:  If provided, only restart these named services.
                      If None, restarts all services.
        """
        to_restart = [s for s in services if targets is None or s.name in targets]
        if not to_restart:
            logger.info("  No matching services found.")
            return

        for s in to_restart:
            logger.info("  Restarting %-20s ...", s.name)
            rc, _, err = self._run(f"sudo gitlab-ctl restart {s.name}", timeout=60)
            if rc == 0:
                logger.info("    OK")
            else:
                logger.warning("    FAILED (rc=%d)  %s", rc, err.strip())

    def reconfigure(self) -> bool:
        """
        Run ``gitlab-ctl reconfigure``, streaming output in real time.

        Returns:
            True if reconfigure exited 0, False otherwise.
        """
        logger.info("")
        logger.info("  Running gitlab-ctl reconfigure (5-10 minutes)...")
        logger.info("")
        rc, _, _ = self._run("sudo gitlab-ctl reconfigure", timeout=900, stream=True)
        logger.info("")
        if rc != 0:
            logger.warning("  reconfigure exited with code %d", rc)
            return False
        logger.info("  reconfigure completed successfully")
        return True

    def tail_services(self, names: List[str], lines: int = 60) -> None:
        """
        Tail recent log lines for each named service.

        Args:
            names: Service names to tail.
            lines: Number of tail lines per service.
        """
        for name in names:
            logger.info("")
            logger.info("  --- %s (last %d lines) ---", name, lines)
            _, out, _ = self._run(
                f"sudo tail -{lines} /var/log/gitlab/{name}/current 2>/dev/null || "
                f"sudo tail -{lines} /var/log/gitlab/{name}/{name}_stderr.log 2>/dev/null || "
                f"echo '(no log found at /var/log/gitlab/{name}/)'",
                timeout=30,
            )
            for line in out.splitlines():
                logger.info("    %s", line)

    def watch(self, interval: int, targets: Optional[List[str]] = None) -> None:
        """
        Poll service status repeatedly until all expected services are up.

        Stops automatically when no "normally up" services are down, or on
        Ctrl+C.

        Args:
            interval: Seconds between polls.
            targets:  If set, only watch these named services.
        """
        import datetime
        poll = 0
        while True:
            poll += 1
            ts = datetime.datetime.now().strftime("%H:%M:%S")
            logger.info("")
            logger.info("  [%s]  poll #%d", ts, poll)
            services = self.get_status()
            if targets:
                services = [s for s in services if s.name in targets]
            self.print_status_table(services)

            down_normally_up = [s for s in services if not s.is_up and s.normally_up]
            if not down_normally_up:
                logger.info("  All expected services are up.")
                break

            logger.info("  Still down: %s — rechecking in %ds...",
                        ", ".join(s.name for s in down_normally_up), interval)
            time.sleep(interval)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    """Build the argument parser."""
    p = argparse.ArgumentParser(
        description="Check and manage GitLab services via SSH.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument(
        "--start",
        action="store_true",
        help="Start any 'normally up' services that are currently down.",
    )
    p.add_argument(
        "--restart",
        action="store_true",
        help="Restart services (all services, or those named with --service).",
    )
    p.add_argument(
        "--reconfigure",
        action="store_true",
        help="Run sudo gitlab-ctl reconfigure (streams output in real time).",
    )
    p.add_argument(
        "--tail",
        nargs="*",
        metavar="SERVICE",
        help=(
            "Tail service logs. With no service names, tails all services that "
            "are down. Pass service names to tail specific ones (e.g. --tail puma nginx)."
        ),
    )
    p.add_argument(
        "--service",
        nargs="+",
        metavar="NAME",
        help="Scope --start / --restart / --tail to specific service(s).",
    )
    p.add_argument(
        "--watch",
        nargs="?",
        const=10,
        type=int,
        metavar="SECONDS",
        help=(
            "Poll status repeatedly until all services are up. "
            "Optional interval in seconds (default: 10)."
        ),
    )
    p.add_argument(
        "--config",
        default="config.json",
        metavar="PATH",
        help="Path to config.json (default: config.json).",
    )
    return p


def section(title: str) -> None:
    """Print a clearly delimited section header."""
    logger.info("")
    logger.info("=" * 60)
    logger.info("  %s", title)
    logger.info("=" * 60)


def main() -> None:
    """Entry point."""
    import datetime
    args = build_parser().parse_args()

    logger.info("=" * 60)
    logger.info("  GitLab Service Manager")
    logger.info("  %s", datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    logger.info("=" * 60)

    mgr = GitLabServiceManager(config_path=args.config)
    logger.info("  Connecting to %s ...", mgr.config["ip_address"])
    if not mgr.connect():
        sys.exit(1)
    logger.info("  Connected")

    try:
        # --reconfigure runs first — it will start all services itself
        if args.reconfigure:
            section("Reconfigure")
            mgr.reconfigure()

        # Always show status
        section("Service Status")
        services = mgr.get_status()
        mgr.print_status_table(services)

        # --start
        if args.start:
            section("Starting Down Services")
            started = mgr.start_services(services, targets=args.service)
            if started:
                logger.info("  Started: %s", ", ".join(started))
                time.sleep(2)
                section("Service Status (after start)")
                services = mgr.get_status()
                mgr.print_status_table(services)

        # --restart
        if args.restart:
            section("Restarting Services")
            mgr.restart_services(services, targets=args.service)
            time.sleep(2)
            section("Service Status (after restart)")
            services = mgr.get_status()
            mgr.print_status_table(services)

        # --tail
        if args.tail is not None:
            section("Service Logs")
            if args.tail:
                # Explicit service names on the flag itself
                tail_targets = args.tail
            elif args.service:
                # Fall back to --service names
                tail_targets = args.service
            else:
                # Default: tail all services that are currently down
                tail_targets = [s.name for s in services if not s.is_up]

            if tail_targets:
                mgr.tail_services(tail_targets)
            else:
                logger.info("  All services are up — nothing to tail.")

        # --watch (runs last so it reflects any start/restart actions above)
        if args.watch is not None:
            section(f"Watching (interval: {args.watch}s)")
            mgr.watch(interval=args.watch, targets=args.service)

    except KeyboardInterrupt:
        logger.info("\n  Interrupted by user")
    finally:
        mgr.disconnect()

    logger.info("")
    logger.info("  Log written to: %s", LOG_PATH)


if __name__ == "__main__":
    main()
