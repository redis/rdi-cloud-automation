# The operator only writes, deletes, and describes the lease item and table. The witness region
# serves no traffic and needs no permissions.
data "aws_iam_policy_document" "lease" {
  statement {
    sid       = "RdiDynamoDBLease"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    resources = local.table_arns
  }
}

resource "aws_iam_policy" "lease" {
  count = var.create_iam_policy ? 1 : 0

  name        = coalesce(var.iam_policy_name, "${var.table_name}-dynamodb-lease")
  description = "RDI operator access to the ${var.table_name} DynamoDB leader election lease table"
  policy      = data.aws_iam_policy_document.lease.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "lease" {
  for_each = var.create_iam_policy ? toset(var.attach_to_role_names) : toset([])

  role       = each.value
  policy_arn = aws_iam_policy.lease[0].arn
}

resource "aws_iam_user_policy_attachment" "lease" {
  for_each = var.create_iam_policy ? toset(var.attach_to_user_names) : toset([])

  user       = each.value
  policy_arn = aws_iam_policy.lease[0].arn
}
