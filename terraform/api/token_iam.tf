resource "aws_iam_role" "token" {
  name = "platform.lambda.${local.api_token_name}.role"
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
            "Resource" : "arn:aws:iam::${var.common.account_id}:role/api_user_*"
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
              "arn:aws:logs:${var.common.region}:${var.common.account_id}:log-group:/aws/lambda/${local.api_token_name}:*"
            ]
          }
        ]
      }
    )
  }
  tags = local.common_tags
}


resource "aws_iam_role" "user" {
  for_each = local.api_users
  name = "api_user_${each.key}"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:sts::${var.common.account_id}:assumed-role/${aws_iam_role.token.name}/${aws_lambda_function.token.function_name}"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
  # managed_policy_arns = [
  #   "arn:aws:iam::aws:policy/AdministratorAccess",
  # ]
  tags = merge(
    { "pin" = "Update this to an int value" },
    local.common_tags
  )
  lifecycle {
    ignore_changes = [ tags["pin"], ]
  }
}

resource "aws_iam_role" "user_jussing" {
  name = "user_jussing"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:sts::${var.common.account_id}:assumed-role/${aws_iam_role.token.name}/${aws_lambda_function.token.function_name}"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
  tags = merge(
    { "pin" = "1234" },
    local.common_tags
  )
}
