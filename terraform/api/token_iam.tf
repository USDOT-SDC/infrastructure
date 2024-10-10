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
  tags = local.common_tags
}

resource "aws_iam_role_policy" "allow_list_iam_role_tags" {
  name = "allow_list_iam_role_tags"
  role = aws_iam_role.token.id
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

resource "aws_iam_role_policy" "allow_logging" {
  name = "allow_logging"
  role = aws_iam_role.token.id
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

resource "random_string" "role_key" {
  for_each    = local.api_users
  length      = 40
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
  special     = false
}

resource "aws_iam_role" "user" {
  for_each = local.api_users
  name     = "api_user_${each.key}"
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
  tags = merge(
    { "key" = random_string.role_key[each.key].result },
    local.common_tags
  )
  lifecycle {
    ignore_changes = [tags["key"], ]
  }
}
