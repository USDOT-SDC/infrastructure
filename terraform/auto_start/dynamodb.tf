resource "aws_dynamodb_table" "auto_start" {
  name         = "instance_auto_start"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "instance_id"

  attribute {
    name = "instance_id"
    type = "S"
  }

  tags = local.tags
}
