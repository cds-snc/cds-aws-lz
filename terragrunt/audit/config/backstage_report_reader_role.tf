resource "aws_iam_role" "backstage_report_reader" {
  name               = "backstage-report-reader"
  assume_role_policy = data.aws_iam_policy_document.backstage_report_reader_trust.json

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

data "aws_iam_policy_document" "backstage_report_reader_trust" {
  statement {
    sid     = "AllowBackstageAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::283582579564:role/backstage-task-execution-role"]
    }
  }
}

resource "aws_iam_policy" "read_cbrid_reports" {
  name   = "read-cbrid-reports"
  path   = "/"
  policy = data.aws_iam_policy_document.read_cbrid_reports.json

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

data "aws_iam_policy_document" "read_cbrid_reports" {
  statement {
    sid     = "GetReportObjects"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::cds-ssc-cbrid-compliance-reports/config-compliance-reports/*"
    ]
  }

  statement {
    sid     = "ListReportPrefix"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::cds-ssc-cbrid-compliance-reports"
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["config-compliance-reports*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "backstage_report_reader" {
  role       = aws_iam_role.backstage_report_reader.name
  policy_arn = aws_iam_policy.read_cbrid_reports.arn
}
