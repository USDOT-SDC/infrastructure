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

resource "aws_dynamodb_table_item" "auto_start_example" {
  table_name = aws_dynamodb_table.auto_starts.name
  hash_key   = aws_dynamodb_table.auto_starts.hash_key

  item = jsonencode(
    {
      "instance_id" : {
        "S" : "i-0daca5caa7c550bab_example"
      },
      "cron_expressions" : {
        "L" : [
          {
            "S" : "55 * * * *"
          },
          {
            "S" : "5 * * * *"
          }
        ]
      },
      "name" : {
        "S" : "ECSDWART01_SchemaExample"
      },
      "timezone" : {
        "S" : "EST"
      }
    }
  )
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


resource "aws_dynamodb_table_item" "maintenance_windows_example" {
  table_name = aws_dynamodb_table.maintenance_windows.name
  hash_key   = aws_dynamodb_table.maintenance_windows.hash_key

  item = jsonencode(
    {
      "maintenance_window_id" : {
        "S" : "Tuesday09_SchemaExample"
      },
      "cron_expression" : {
        "S" : "0 9 * * 2"
      },
      "duration" : {
        "S" : "8:00"
      },
      "timezone" : {
        "S" : "EST"
      }
    }
  )
}
