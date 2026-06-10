resource "aws_iam_role" "cost_report_config_reader" {
  name               = "cost-report-config-reader"
  assume_role_policy = data.aws_iam_policy_document.cost_report_config_reader_trust.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "cost_report_config_reader_trust" {
  statement {
    sid     = "AllowCostReportLambdaAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::659087519042:role/cost_report_lambda"]
    }
  }
}

resource "aws_iam_policy" "cost_report_config_reader" {
  name   = "cost-report-config-reader"
  policy = data.aws_iam_policy_document.cost_report_config_reader.json
  tags   = local.common_tags
}

data "aws_iam_policy_document" "cost_report_config_reader" {
  statement {
    sid    = "QueryConfigAggregator"
    effect = "Allow"
    actions = [
      "config:SelectAggregateResourceConfig",
      "config:DescribeConfigurationAggregators",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "cost_report_config_reader" {
  role       = aws_iam_role.cost_report_config_reader.name
  policy_arn = aws_iam_policy.cost_report_config_reader.arn
}
