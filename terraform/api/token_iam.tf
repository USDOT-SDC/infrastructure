resource "aws_iam_role" "token" {
  #   name = "platform.lambda.api_token.role"
  name = "api_generate_token"
  path = "/service-role/"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
  inline_policy {
    name = "allow_list_iam_role_tags"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "AllowListRoleTags",
            "Effect" : "Allow",
            "Action" : "iam:ListRoleTags",
            "Resource" : "arn:aws:iam::${var.common.account_id}:role/user_*"
          }
        ]
      }
    )
  }
  inline_policy {
    name = "allow_logging"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "AllowCreateLogGroup",
            "Effect" : "Allow",
            "Action" : "logs:CreateLogGroup",
            "Resource" : "arn:aws:logs:${var.common.region}:${var.common.account_id}:*"
          },
          {
            "Sid" : "AllowCreatePutLogs",
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : [
              "arn:aws:logs:${var.common.region}:${var.common.account_id}:log-group:/aws/lambda/${aws_lambda_function.token.function_name}:*"
            ]
          }
        ]
      }
    )
  }
  tags = local.common_tags
}
