resource "aws_iam_role" "billing_extract_tags" {
  name               = "BillingExtractTags"
  assume_role_policy = data.aws_iam_policy_document.billing_extract_tags_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "billing_extract_tags_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
      "lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "billing_extract_tags" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/billing_extract_tags:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject*",
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:DeleteObject*",
      "s3:GetBucketLocation"
    ]
    resources = [
      module.billing_extract_tags.s3_bucket_arn,
      "${module.billing_extract_tags.s3_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_policy" "billing_extract_tags" {
  name   = "BillingExtractTags"
  policy = data.aws_iam_policy_document.billing_extract_tags.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "billing_extract_tags" {
  role       = aws_iam_role.billing_extract_tags.name
  policy_arn = aws_iam_policy.billing_extract_tags.arn
}

data "aws_iam_policy" "org_read_only" {
  arn = "arn:aws:iam::aws:policy/AWSOrganizationsReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "org_read_only" {
  role       = aws_iam_role.billing_extract_tags.name
  policy_arn = data.aws_iam_policy.org_read_only.arn
}

data "aws_iam_policy" "lambda_insights" {
  name = "CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "lambda_insights" {
  role       = aws_iam_role.billing_extract_tags.name
  policy_arn = data.aws_iam_policy.lambda_insights.arn
}
