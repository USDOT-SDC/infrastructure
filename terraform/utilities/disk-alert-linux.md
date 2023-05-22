## Disk Alert for Linux Instances

### `data.tf`
```json
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config  = {
    region = "us-east-1"
    bucket = "{env}.{domain}.terraform"
    key    = "infrastructure/terraform/terraform.tfstate"
  }
}
```

### `variables.tf`
```terraform
locals {
  instance_maintenance_bucket = data.terraform_remote_state.infrastructure.outputs.disk_alert_linux_script.bucket
  disk_alert_script_key       = data.terraform_remote_state.infrastructure.outputs.disk_alert_linux_script.key
}
```

### `iam.tf`
```json
resource "aws_iam_policy" "instance_maintenance_bucket" {
  name        = "instance_maintenance_bucket"
  description = "Allow read from instance maintenance bucket"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:Get*",
            "s3:List*"
          ],
          "Resource" : "arn:aws:s3:::${local.instance_maintenance_bucket}*"
        }
      ]
    }
  )
}
```

### `some-file.tf`
```json
resource "aws_s3_object" "some_file" {
  bucket = "some-bucket"
  key    = "user_data.sh"
  content = templatefile(
    "user_data.sh.tftpl", 
    {
      instance_maintenance_bucket = local.instance_maintenance_bucket
      disk_alert_script_key       = local.disk_alert_script_key
    }
  )
}
```

### `user_data.sh.tftpl`
```shell
echo_to_log "Setup the disk monitor alert..."
DISK_ALERT_SCRIPT_PATH="/usr/local/bin/disk-alert-linux.py"
# get the script
/usr/local/bin/aws s3 cp s3://${instance_maintenance_bucket}/${disk_alert_script_key} $DISK_ALERT_SCRIPT_PATH
# make it executable
chmod +x $DISK_ALERT_SCRIPT_PATH
# write out current crontab to temp file
crontab -l > current_crontab
# echo new cron into temp file
echo "0 2 * * * python3 $DISK_ALERT_SCRIPT_PATH" >> current_crontab
# install new cron file from temp file
crontab current_crontab
# remove the temp file
rm current_crontab
echo_to_log "Setup the disk monitor alert: Done!"
```