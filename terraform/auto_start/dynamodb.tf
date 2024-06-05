resource "aws_dynamodb_table" "auto_starts" {
  name         = "instance_auto_starts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "instance_id"

  attribute {
    name = "instance_id"
    type = "S"
  }

  tags = local.tags
}

resource "aws_dynamodb_table" "maintenance_windows" {
  name         = "instance_maintenance_windows"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "maintenance_window_id"

  attribute {
    name = "maintenance_window_id"
    type = "S"
  }

  tags = local.tags
}
