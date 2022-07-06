# === Aurora Role ===
resource "aws_iam_role" "aurora" {
  name       = "${local.module}_aurora_role"
  tags = local.tags
}
resource "aws_iam_policy" "aurora" {
  name   = "${local.module}_aurora_policy"
  policy = file("${local.module}/aurora_policy.json")
  tags = local.tags
}
resource "aws_iam_policy_attachment" "aurora" {
  name       = "${local.module}_aurora_policy_attachment"
  roles      = [aws_iam_role.aurora.name]
  policy_arn = aws_iam_policy.aurora.arn
}


# === Glue Role ===
resource "aws_iam_role" "glue" {
  name       = "${local.module}_glue_role"
  tags = local.tags
}
resource "aws_iam_policy" "glue" {
  name   = "${local.module}_glue_policy"
  policy = file("${local.module}/glue_policy.json")
  tags = local.tags
}
resource "aws_iam_policy_attachment" "glue" {
  name       = "${local.module}_glue_policy_attachment"
  roles      = [aws_iam_role.glue.name]
  policy_arn = aws_iam_policy.glue.arn
}
