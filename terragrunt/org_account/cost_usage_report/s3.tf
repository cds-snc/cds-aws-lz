#
# Cost and usage report
#
module "cost_usage_report" {
  source      = "github.com/cds-snc/terraform-modules//S3?ref=v9.6.8"
  bucket_name = "cds-cost-usage-report"

  versioning = {
    enabled = true
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
        "arn:aws:cur:us-east-1:659087519042:definition/*",
        "arn:aws:bcm-data-exports:us-east-1:659087519042:export/*"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "aws:SourceAccount"
      values   = ["659087519042"]
    }
  }

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::066023111852:root"]
    }
    actions = [
      "s3:ListMultipartUploadParts",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      module.cost_usage_report.s3_bucket_arn,
      "${module.cost_usage_report.s3_bucket_arn}/*"
    ]
  }
}

#
# Account billing tags
#
module "billing_extract_tags" {
  source      = "github.com/cds-snc/terraform-modules//S3?ref=v9.6.8"
  bucket_name = "cds-account-billing-extract-tags"
  acl         = null

  versioning = {
    enabled = true
  }

  billing_tag_value = var.billing_code
}

resource "aws_s3_bucket_policy" "billing_extract_tags" {
  bucket = module.billing_extract_tags.s3_bucket_id
  policy = data.aws_iam_policy_document.billing_extract_tags_bucket.json
}

data "aws_iam_policy_document" "billing_extract_tags_bucket" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.billing_extract_tags.arn]
    }
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

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::066023111852:root"]
    }
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      module.billing_extract_tags.s3_bucket_arn,
      "${module.billing_extract_tags.s3_bucket_arn}/*",
    ]
  }
}
