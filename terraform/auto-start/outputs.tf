output "dynamodb_tables" {
  value = {
    auto_starts = {
      name     = aws_dynamodb_table.auto_starts.name
      hash_key = aws_dynamodb_table.auto_starts.hash_key
    }
    maintenance_windows = {
      name     = aws_dynamodb_table.maintenance_windows.name
      hash_key = aws_dynamodb_table.maintenance_windows.hash_key
    }
  }
}
