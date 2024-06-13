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

# resource "aws_dynamodb_table_item" "auto_start_example" {
#   table_name = aws_dynamodb_table.auto_starts.name
#   hash_key   = aws_dynamodb_table.auto_starts.hash_key

#   item = jsonencode(
#     {
#       "instance_id" : {
#         "S" : "i-0daca5caa7c550bab"
#       },
#       "cron_expressions" : {
#         "L" : [
#           {
#             "S" : "0 18 * * 6"
#           },
#           {
#             "S" : "0 0 * * 0"
#           }
#         ]
#       },
#       "name" : {
#         "S" : "ECSDWART01"
#       },
#       "timezone" : {
#         "S" : "EST"
#       },
#       "terraform_configured" : { # lets everyone know this item is managed by Terraform
#         "BOOL" : true
#       }
#     }
#   )
# }

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


resource "aws_dynamodb_table_item" "maintenance_window_saturday_maint" {
  table_name = aws_dynamodb_table.maintenance_windows.name
  hash_key   = aws_dynamodb_table.maintenance_windows.hash_key

  item = jsonencode(
    {
      "maintenance_window_id" : {
        "S" : "SaturdayMaintenance"
      },
      "cron_expression" : {
        "S" : "0 18 * * 6"
      },
      "duration" : {
        "S" : "6:00"
      },
      "timezone" : {
        "S" : "EST"
      },
      "terraform_configured" : { # lets everyone know this item is managed by Terraform
        "BOOL" : true
      }
    }
  )
}

resource "aws_dynamodb_table_item" "maintenance_window_sunday_scan" {
  table_name = aws_dynamodb_table.maintenance_windows.name
  hash_key   = aws_dynamodb_table.maintenance_windows.hash_key

  item = jsonencode(
    {
      "maintenance_window_id" : {
        "S" : "SundayScan"
      },
      "cron_expression" : {
        "S" : "0 0 * * 0"
      },
      "duration" : {
        "S" : "6:00"
      },
      "timezone" : {
        "S" : "EST"
      },
      "terraform_configured" : { # lets everyone know this item is managed by Terraform
        "BOOL" : true
      }
    }
  )
}
