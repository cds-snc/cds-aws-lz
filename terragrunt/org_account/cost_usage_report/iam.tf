#
# Lambda function to extract account tags and write them to the Data Lake
#
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
      "s3:PutObject"
    ]
    resources = [
      "${local.data_lake_raw_s3_bucket_arn}/operations/aws/organization/account-tags.json",
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

#
# Replicate the Cost and Usage Report data to the Data Lake
#
resource "aws_iam_role" "cur_replicate" {
  name               = "CostUsageReplicateToDataLake"
  assume_role_policy = data.aws_iam_policy_document.cur_replicate_assume.json
  tags               = local.common_tags
}

resource "aws_iam_policy" "cur_replicate" {
  name   = "CostUsageReplicateToDataLake"
  policy = data.aws_iam_policy_document.cur_replicate.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cur_replicate" {
  role       = aws_iam_role.cur_replicate.name
  policy_arn = aws_iam_policy.cur_replicate.arn
}

data "aws_iam_policy_document" "cur_replicate_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "cur_replicate" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      module.cost_usage_report.s3_bucket_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl"
    ]
    resources = [
      "${module.cost_usage_report.s3_bucket_arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]
    resources = [
      "${local.data_lake_raw_s3_bucket_arn}/*"
    ]
  }
}