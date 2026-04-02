#!/usr/bin/env python3
"""
GitLab upgrade orchestrator for RHEL-based EC2 instances.

Handles automated upgrade path calculation, backup verification,
SSH-based upgrade execution with resilience, and post-upgrade validation.
"""

import json
import sys
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Dict, Optional, Tuple, Any
import time

import boto3
import paramiko
import requests
from botocore.exceptions import ClientError


class GitLabUpgrader:
    """Orchestrates GitLab version upgrades with safety checks and logging."""

    def __init__(self, config_path: str = "config.json"):
        """
        Initialize upgrader with configuration.

        Args:
            config_path: Path to JSON config file containing instance details
        """
        self.config = self._load_config(config_path)
        
        # Set AWS profile BEFORE creating clients
        os.environ['AWS_PROFILE'] = self.config['aws_profile']
        
        self.log_file: Optional[Path] = None
        self.ssh_client: Optional[paramiko.SSHClient] = None
        self.status_file = Path("status.json")
        self.status: Dict = self._load_status()
        
        # AWS clients - now they'll use the correct profile
        self.ec2: Any = boto3.client('ec2', region_name='us-east-1')
        self.s3: Any = boto3.client('s3', region_name='us-east-1')
        
    def _load_config(self, config_path: str) -> Dict:
        """Load and validate configuration file."""
        with open(config_path, 'r') as f:
            config = json.load(f)
        
        # Expand Windows environment variables in paths
        config['ssh_key_path'] = os.path.expandvars(config['ssh_key_path'])
        
        required_keys = ['instance_id', 'ip_address', 'ssh_key_path', 'ssh_user', 'aws_profile']
        for key in required_keys:
            if key not in config:
                raise ValueError(f"Missing required config key: {key}")
        
        return config
    
    def _load_status(self) -> Dict:
        """Load or initialize status tracking file."""
        if self.status_file.exists():
            with open(self.status_file, 'r') as f:
                return json.load(f)
        return {"current_step": "init", "last_success": None}
    
    def _save_status(self, step: str):
        """Save current step to status file."""
        self.status["current_step"] = step
        self.status["last_success"] = step
        self.status["timestamp"] = datetime.now(timezone.utc).isoformat()
        with open(self.status_file, 'w') as f:
            json.dump(self.status, f, indent=2)
        self._log(f"✓ Saved status: {step}")
    
    def _reset_status(self):
        """Clear status file after successful completion."""
        if self.status_file.exists():
            self.status_file.unlink()
        self._log("✓ Reset status file")
    
    def _log(self, message: str):
        """Write message to console and log file."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] {message}"
        print(log_entry)
        
        if self.log_file:
            with open(self.log_file, 'a', encoding='utf-8') as f:
                f.write(log_entry + "\n")
    
    def _confirm(self, prompt: str) -> bool:
        """Prompt user for yes/no confirmation."""
        self._log(prompt)  # Log the prompt with timestamp
        while True:
            response = input(f"{" "*21} (y/n): ").strip().lower()
            if response in ['y', 'yes']:
                self._log(f"User response: yes")
                return True
            elif response in ['n', 'no']:
                self._log(f"User response: no")
                return False
            print("Please enter 'y' or 'n'")
    
    def check_instance_state(self) -> bool:
        """Verify EC2 instance is running."""
        self._log(f"Checking instance state: {self.config['instance_id']}")
        
        try:
            response = self.ec2.describe_instances(
                InstanceIds=[self.config['instance_id']]
            )
            state = response['Reservations'][0]['Instances'][0]['State']['Name']
            
            self._log(f"Instance state: {state}")
            
            if state != 'running':
                self._log(f"ERROR: Instance must be running (current: {state})")
                return False
            
            self._save_status("instance_checked")
            return True
            
        except ClientError as e:
            self._log(f"ERROR: Failed to check instance: {e}")
            return False
    
    def check_backups(self) -> bool:
        """
        Verify recent backups exist in S3.
        
        Returns:
            True if backups are acceptable, False otherwise
        """
        self._log("Checking S3 backups...")
        bucket = "prod-dot-sdc-gitlab-backup-004118380849"
        
        try:
            # List all objects
            response = self.s3.list_objects_v2(Bucket=bucket)
            
            if 'Contents' not in response:
                self._log("ERROR: No backups found in S3 bucket")
                return False
            
            # Find latest backup files
            backup_tar = None
            secrets_json = None
            
            for obj in response['Contents']:
                key = obj.get('Key', '')
                last_modified = obj.get('LastModified')
                
                if key.endswith('_gitlab_backup.tar'):
                    if not backup_tar or (last_modified and backup_tar.get('LastModified') and last_modified > backup_tar['LastModified']):
                        backup_tar = obj
                elif key.endswith('gitlab-secrets.json'):
                    if not secrets_json or (last_modified and secrets_json.get('LastModified') and last_modified > secrets_json['LastModified']):
                        secrets_json = obj
            
            if not backup_tar or not secrets_json:
                self._log("ERROR: Missing backup files (need both .tar and secrets.json)")
                return False
            
            # Display backup info
            self._log("" + "="*60)
            self._log("LATEST BACKUPS:")
            self._log(f"  Backup TAR:    {backup_tar.get('Key', 'unknown')}")
            self._log(f"    Last Modified: {backup_tar.get('LastModified', 'unknown')}")
            self._log(f"    Size: {backup_tar.get('Size', 0) / (1024**3):.2f} GB")
            self._log("")
            self._log(f"  Secrets JSON:  {secrets_json.get('Key', 'unknown')}")
            self._log(f"    Last Modified: {secrets_json.get('LastModified', 'unknown')}")
            self._log("="*60)
            
            # Check backup age
            now = datetime.now(timezone.utc)
            backup_last_modified = backup_tar.get('LastModified')
            
            if backup_last_modified:
                backup_age = now - backup_last_modified
                
                if backup_age > timedelta(hours=24):
                    self._log(f"⚠ WARNING: Backup is {backup_age.days} days old (expected < 24hrs)")
                    
                    if self._confirm("Create manual backup before proceeding?"):
                        self._log("Please run manual backup:")
                        self._log("  SSH to instance and run: sudo gitlab-backup create")
                        self._log("  Then re-run this script")
                        return False
                    
                    if not self._confirm("Proceed with old backup anyway?"):
                        self._log("Upgrade aborted by user")
                        return False
            
            if not self._confirm("Backups verified. Proceed with upgrade?"):
                self._log("Upgrade aborted by user")
                return False
            
            self._save_status("backups_checked")
            return True
            
        except ClientError as e:
            self._log(f"ERROR: Failed to check S3 backups: {e}")
            return False
    
    def _connect_ssh(self, retries: int = 3) -> bool:
        """
        Establish SSH connection with retry logic.
        
        Args:
            retries: Number of connection attempts
            
        Returns:
            True if connected, False otherwise
        """
        for attempt in range(retries):
            try:
                if self.ssh_client:
                    self.ssh_client.close()
                
                self.ssh_client = paramiko.SSHClient()
                self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                
                self._log(f"Connecting to {self.config['ip_address']} (attempt {attempt + 1}/{retries})")
                
                self.ssh_client.connect(
                    hostname=self.config['ip_address'],
                    username=self.config['ssh_user'],
                    key_filename=self.config['ssh_key_path'],
                    timeout=30,
                    banner_timeout=30
                )
                
                # Enable keepalive
                transport = self.ssh_client.get_transport()
                if transport:
                    transport.set_keepalive(30)
                
                self._log("✓ SSH connection established")
                return True
                
            except Exception as e:
                self._log(f"SSH connection failed: {e}")
                if attempt < retries - 1:
                    time.sleep(5)
        
        return False
    
    def _run_ssh_command(self, command: str, timeout: int = 3600, stream: bool = False) -> Tuple[int, str, str]:
        """
        Execute command via SSH with retry logic.
        
        Args:
            command: Command to execute
            timeout: Command timeout in seconds
            stream: Whether to stream output in real-time
            
        Returns:
            Tuple of (exit_code, stdout, stderr)
        """
        # Ensure we have a valid SSH connection
        if not self.ssh_client:
            if not self._connect_ssh():
                return (1, "", "Failed to establish SSH connection")
        
        # After connection attempt, ssh_client should be set
        assert self.ssh_client is not None, "SSH client should be initialized"
        
        transport = self.ssh_client.get_transport()
        if not transport or not transport.is_active():
            if not self._connect_ssh():
                return (1, "", "Failed to establish SSH connection")
        
        # Re-assert after potential reconnection
        assert self.ssh_client is not None, "SSH client should be initialized after reconnection"
        
        try:
            self._log(f"Executing: {command}")
            stdin, stdout, stderr = self.ssh_client.exec_command(command, timeout=timeout)
            
            if stream:
                # Stream output in real-time
                stdout_lines = []
                stderr_lines = []
                
                while not stdout.channel.exit_status_ready():
                    if stdout.channel.recv_ready():
                        line = stdout.channel.recv(1024).decode('utf-8')
                        print(line, end='')
                        stdout_lines.append(line)
                    
                    if stderr.channel.recv_stderr_ready():
                        line = stderr.channel.recv_stderr(1024).decode('utf-8')
                        print(line, end='', file=sys.stderr)
                        stderr_lines.append(line)
                    
                    time.sleep(0.1)
                
                # Get remaining output
                stdout_lines.append(stdout.read().decode('utf-8'))
                stderr_lines.append(stderr.read().decode('utf-8'))
                
                exit_code = stdout.channel.recv_exit_status()
                return (exit_code, ''.join(stdout_lines), ''.join(stderr_lines))
            else:
                stdout_str = stdout.read().decode('utf-8')
                stderr_str = stderr.read().decode('utf-8')
                exit_code = stdout.channel.recv_exit_status()
                
                return (exit_code, stdout_str, stderr_str)
                
        except Exception as e:
            self._log(f"Command execution failed: {e}")
            return (1, "", str(e))
    
    def get_current_version(self) -> Optional[str]:
        """
        Retrieve current GitLab version from instance.
        
        Returns:
            Version string (e.g., "18.3.1") or None if failed
        """
        self._log("Retrieving current GitLab version...")
        
        if not self._connect_ssh():
            return None
        
        # Try multiple methods to get version
        commands = [
            "sudo gitlab-rake gitlab:env:info | grep 'GitLab information'",
            "sudo cat /opt/gitlab/version-manifest.txt | head -1",
            "rpm -qa gitlab-ee | head -1"
        ]
        
        for cmd in commands:
            exit_code, stdout, stderr = self._run_ssh_command(cmd)
            
            if exit_code == 0 and stdout:
                # Parse version from output
                # Format examples:
                # "GitLab information => 18.3.1-ee"
                # "gitlab-ee 18.3.1"
                # "gitlab-ee-18.3.1-ee.0.el8.x86_64"
                
                import re
                version_match = re.search(r'(\d+\.\d+\.\d+)', stdout)
                if version_match:
                    version = version_match.group(1)
                    self._log(f"✓ Current version: {version}")
                    self._save_status("version_retrieved")
                    return version
        
        self._log("ERROR: Could not determine GitLab version")
        return None
    
    def get_upgrade_path(self, current_version: str) -> Optional[Dict]:
        """
        Query GitLab upgrade path API for next step.
        
        Args:
            current_version: Current GitLab version (e.g., "18.3.1")
            
        Returns:
            Dict with upgrade path info or None if failed
        """
        self._log(f"Querying upgrade path API for version {current_version}...")
        
        try:
            # The API returns supported and all versions
            url = "https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/path.json"
            
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            # Get list of all versions (these are the required stops)
            all_versions = data.get('all', [])
            
            if not all_versions:
                self._log("ERROR: No versions found in upgrade path API")
                return None
            
            # Parse current version
            from packaging import version
            current_ver = version.parse(current_version)
            
            # Find all versions greater than current
            future_versions = []
            for ver_str in all_versions:
                ver = version.parse(ver_str)
                if ver > current_ver:
                    future_versions.append(ver_str)
            
            if not future_versions:
                self._log(f"✓ Already at latest version: {current_version}")
                return None
            
            # Sort versions
            future_versions.sort(key=version.parse)
            
            # Display upgrade path
            self._log("" + "="*60)
            self._log("UPGRADE PATH:")
            self._log(f"  Current: {current_version}")
            
            for ver in future_versions:
                self._log(f"  → {ver}")
            
            # Next version is the first in the future list
            next_version = future_versions[0]
            
            self._log(f"Next upgrade target: {next_version}")
            self._log("="*60)
            
            upgrade_info = {
                'current_version': current_version,
                'next_version': next_version,
                'upgrade_path': future_versions
            }
            
            self._save_status("upgrade_path_retrieved")
            return upgrade_info
            
        except Exception as e:
            self._log(f"ERROR: Failed to get upgrade path: {e}")
            import traceback
            self._log(traceback.format_exc())
            return None
    
    def perform_upgrade(self, target_version: str) -> bool:
        """
        Execute the GitLab package upgrade.
        
        Args:
            target_version: Target GitLab version to upgrade to
            
        Returns:
            True if upgrade succeeded, False otherwise
        """
        self._log(f"Starting upgrade to version {target_version}...")
        
        if not self._confirm(f"Proceed with upgrade to {target_version}?"):
            self._log("Upgrade aborted by user")
            return False
        
        # Ensure SSH connection
        if not self._connect_ssh():
            return False
        
        # Step 1: Update package cache (excluding gitlab-ee to prevent yum from
        # jumping to the latest available version instead of the pinned target)
        self._log("[1/3] Updating system packages (excluding gitlab-ee)...")
        self._save_status("upgrade_yum_update")

        exit_code, stdout, stderr = self._run_ssh_command(
            "sudo yum update -y --exclude=gitlab-ee",
            timeout=600,
            stream=True
        )

        if exit_code != 0:
            self._log(f"ERROR: yum update failed (exit {exit_code})")
            self._log(f"STDERR: {stderr}")
            return False
        
        # Step 2: Install target GitLab version
        self._log(f"[2/3] Installing gitlab-ee-{target_version}...")
        self._save_status(f"upgrade_install_{target_version}")
        
        exit_code, stdout, stderr = self._run_ssh_command(
            f"sudo yum install -y gitlab-ee-{target_version}",
            timeout=3600,
            stream=True
        )
        
        if exit_code != 0:
            self._log(f"ERROR: GitLab installation failed (exit {exit_code})")
            self._log(f"STDERR: {stderr}")
            
            # Try to determine state
            self._log("Attempting to determine upgrade state...")
            new_version = self.get_current_version()
            if new_version == target_version:
                self._log(f"✓ Version check shows {target_version} - upgrade may have succeeded despite error")
            else:
                return False
        
        # Step 3: Reconfigure GitLab
        self._log("[3/3] Reconfiguring GitLab (this may take 5-10 minutes)...")
        self._save_status("upgrade_reconfigure")
        
        exit_code, stdout, stderr = self._run_ssh_command(
            "sudo gitlab-ctl reconfigure",
            timeout=1200,
            stream=True
        )
        
        if exit_code != 0:
            self._log(f"WARNING: gitlab-ctl reconfigure returned exit code {exit_code}")
            self._log(f"STDERR: {stderr}")
        
        self._save_status("upgrade_complete")
        return True
    
    def verify_upgrade(self) -> bool:
        """
        Run post-upgrade validation checks.
        
        Returns:
            True if validation passed, False otherwise
        """
        self._log("" + "="*60)
        self._log("POST-UPGRADE VALIDATION")
        self._log("="*60)
        
        # Check new version
        new_version = self.get_current_version()
        if not new_version:
            self._log("ERROR: Could not verify new version")
            return False
        
        # Check service status
        self._log("Checking GitLab services...")
        exit_code, stdout, stderr = self._run_ssh_command(
            "sudo gitlab-ctl status",
            timeout=60
        )
        
        if exit_code != 0:
            self._log(f"ERROR: gitlab-ctl status failed (exit {exit_code})")
            self._log(f"OUTPUT:\n{stdout}")
            return False
        
        self._log("GitLab services status:")
        self._log(stdout)
        
        # Check for any down services
        if 'down:' in stdout.lower():
            self._log("⚠ WARNING: Some services appear to be down")
            return False
        
        self._log("✓ All services running")
        
        # Remind about web UI check
        self._log("" + "="*60)
        self._log("MANUAL VERIFICATION REQUIRED:")
        self._log("  1. Login to an SDC workstation")
        self._log("  2. Navigate to: https://gitlab.prod.sdc.dot.gov/")
        self._log("  3. Verify the web UI loads correctly")
        self._log("  4. Check the version in Admin > Overview")
        self._log("="*60)
        
        self._save_status("validation_complete")
        return True
    
    def cleanup(self):
        """Close connections and cleanup resources."""
        if self.ssh_client:
            self.ssh_client.close()
            self._log("✓ Closed SSH connection")
    
    def run(self) -> int:
        """Execute the full upgrade workflow."""
        try:
            # Initialize logging
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            self.log_file = Path("logs") / f"upgrade_{timestamp}.log"
            self.log_file.parent.mkdir(exist_ok=True)
            
            self._log("="*60)
            self._log("GitLab Upgrade Script - Starting")
            self._log("="*60)
            
            # Resume from last successful step if status file exists
            if self.status["last_success"]:
                self._log(f"Resuming from last successful step: {self.status['last_success']}")
                if not self._confirm("Continue from previous run?"):
                    self._reset_status()
            
            # Step 1: Check instance state
            if self.status["last_success"] in [None, "init"]:
                if not self.check_instance_state():
                    return 1
            
            # Step 2: Verify backups
            if self.status["last_success"] in [None, "init", "instance_checked"]:
                if not self.check_backups():
                    return 1
            
            # Step 3: Get current version
            current_version = self.get_current_version()
            if not current_version:
                return 1
            
            # Step 4: Get upgrade path
            upgrade_data = self.get_upgrade_path(current_version)
            if not upgrade_data or 'next_version' not in upgrade_data:
                self._log("ERROR: Could not determine upgrade path")
                return 1
            
            target_version = upgrade_data['next_version']
            
            # Update log filename with version info
            new_log_file = Path("logs") / f"{current_version}_to_{target_version}_{timestamp}.log"
            if self.log_file and self.log_file.exists():
                self.log_file.rename(new_log_file)
                self.log_file = new_log_file
            
            # Step 5: Perform upgrade
            if not self.perform_upgrade(target_version):
                self._log("ERROR: Upgrade failed")
                return 1
            
            # Step 6: Verify upgrade
            if not self.verify_upgrade():
                self._log("WARNING: Post-upgrade validation had issues")
                self._log("Please investigate manually before proceeding")
                return 1
            
            # Success - clear status file
            self._reset_status()
            
            self._log("" + "="*60)
            self._log("✓ UPGRADE COMPLETE")
            self._log(f"  From: {current_version}")
            self._log(f"  To:   {target_version}")
            self._log(f"  Log:  {self.log_file}")
            self._log("="*60)
            
            return 0
            
        except KeyboardInterrupt:
            self._log("\nUpgrade interrupted by user (Ctrl+C)")
            return 130
        except Exception as e:
            self._log(f"\n\nFATAL ERROR: {e}")
            import traceback
            self._log(traceback.format_exc())
            return 1
        finally:
            self.cleanup()


def main():
    """Main entry point."""
    upgrader = GitLabUpgrader()
    
    # Set AWS profile from config
    os.environ['AWS_PROFILE'] = upgrader.config['aws_profile']
    
    exit_code = upgrader.run()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()