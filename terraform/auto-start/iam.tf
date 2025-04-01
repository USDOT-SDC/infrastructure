resource "aws_iam_role" "this" {
  name = "instance_auto_start_role"
  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow"
          Action : "sts:AssumeRole",
          Principal : {
            Service : "lambda.amazonaws.com",
            AWS : "arn:aws:iam::${var.common.account_id}:root"
          },
        }
      ]
    }

  )
  tags = local.common_tags
}

resource "aws_iam_role_policy" "this" {
  name = "instance_auto_start_policy"
  role = aws_iam_role.this.id
  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Sid : "ReadOnlyDynamoDB",
          Effect : "Allow",
          Action : [
            "dynamodb:GetItem",
            "dynamodb:BatchGetItem",
            "dynamodb:Scan",
            "dynamodb:Query",
            "dynamodb:ConditionCheckItem"
          ],
          Resource : [
            aws_dynamodb_table.auto_starts.arn,
            aws_dynamodb_table.maintenance_windows.arn,
          ]
        },
        {
          Sid : "DescribeStartInstances",
          Effect : "Allow",
          Action : [
            "ec2:DescribeInstances",
            "ec2:StartInstances"
          ]
          Resource : "*"
        },
        {
          Sid : "CreateLogGroup"
          Effect : "Allow",
          Action : "logs:CreateLogGroup",
          Resource : "arn:aws:logs:${var.common.region}:${var.common.account_id}:*"
        },

        {
          Sid : "Logging"
          Effect : "Allow",
          Action : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource : [
            "arn:aws:logs:${var.common.region}:${var.common.account_id}:log-group:/aws/lambda/${local.instance_auto_start_function_name}:*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policies_exclusive" "this" {
  role_name = aws_iam_role.this.name
  policy_names = [
    aws_iam_role_policy.this.name,
  ]
}
