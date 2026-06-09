data "aws_iam_policy_document" "cost_report_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cost_report" {
  name               = "cost_report_lambda"
  assume_role_policy = data.aws_iam_policy_document.cost_report_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "cost_report" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cost_report"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cost_report:*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ce:GetCostAndUsage"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.cost_report_bucket.s3_bucket_arn}/${local.report_prefix}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::886481071419:role/cost-report-config-reader"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "organizations:ListAccounts",
      "organizations:ListTagsForResource"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cost_report" {
  name   = "cost_report_lambda"
  policy = data.aws_iam_policy_document.cost_report.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cost_report" {
  role       = aws_iam_role.cost_report.name
  policy_arn = aws_iam_policy.cost_report.arn
}


