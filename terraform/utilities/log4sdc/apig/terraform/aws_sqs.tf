resource "aws_sqs_queue" "log4sdc_sqs" {
  name                      = "log4sdc-sqs"
  delay_seconds             = 0              // how long to delay delivery of records
  max_message_size          = 262144         // = 256KiB, which is the limit set by AWS
  message_retention_seconds = 300            // = 5 minutes in seconds
  receive_wait_time_seconds = 10             // how long to wait for a record to stream in when ReceiveMessage is called
  #sqs_managed_sse_enabled = true
  kms_master_key_id                 = "alias/aws/sqs"
}


resource "aws_lambda_event_source_mapping" "log4sdc_sqs_lambda" {
  event_source_arn = aws_sqs_queue.log4sdc_sqs.arn
  function_name    = "arn:aws:lambda:${var.region}:${local.account_id}:function:${local.environment}-log4sdc-elasticsearch-publisher"
}


