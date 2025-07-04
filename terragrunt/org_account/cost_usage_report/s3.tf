#
# Cost and usage report
#
module "cost_usage_report" {
  source      = "github.com/cds-snc/terraform-modules//S3?ref=v9.6.8"
  bucket_name = "cds-cost-usage-report"

  versioning = {
    enabled = true
  }

  replication_configuration = {
    role = aws_iam_role.cur_replicate.arn

    rules = [
      {
        id       = "send-to-data-lake"
        priority = 10
        destination = {
          bucket = local.data_lake_raw_s3_bucket_arn
        }
      }
    ]
  }

  billing_tag_value = var.billing_code
}

resource "aws_s3_bucket_policy" "cost_usage_report" {
  bucket = module.cost_usage_report.s3_bucket_id
  policy = data.aws_iam_policy_document.cost_usage_report.json
}

data "aws_iam_policy_document" "cost_usage_report" {
  statement {
    sid    = "EnableAWSDataExportsToWriteToS3AndCheckPolicy"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "bcm-data-exports.amazonaws.com",
        "billingreports.amazonaws.com"
      ]
    }
    actions = [
      "s3:PutObject",
      "s3:GetBucketPolicy"
    ]
    resources = [
      module.cost_usage_report.s3_bucket_arn,
      "${module.cost_usage_report.s3_bucket_arn}/*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:cur:us-east-1:${var.account_id}:definition/*",
        "arn:aws:bcm-data-exports:us-east-1:${var.account_id}:export/*"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
  statement {
    sid    = "DenyNonSSLRequests"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      module.cost_usage_report.s3_bucket_arn,
      "${module.cost_usage_report.s3_bucket_arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
