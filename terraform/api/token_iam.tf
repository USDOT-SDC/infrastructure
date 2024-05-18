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
            "Resource" : "arn:aws:iam::505135622787:role/user_*"
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
            "Resource" : "arn:aws:logs:us-east-1:505135622787:*"
          },
          {
            "Sid" : "AllowCreatePutLogs",
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : [
              "arn:aws:logs:us-east-1:505135622787:log-group:/aws/lambda/api_token:*"
            ]
          }
        ]
      }
    )
  }
  tags = local.common_tags
}
