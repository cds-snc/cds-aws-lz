module "cost_report_bucket" {
  source      = "github.com/cds-snc/terraform-modules//S3?ref=v9.6.8"
  bucket_name = local.report_bucket_name

  versioning = {
    enabled = true
  }

  billing_tag_value = var.billing_code
}

resource "aws_s3_bucket_policy" "cost_report_bucket" {
  bucket = module.cost_report_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.cost_report_bucket.json
}

data "aws_iam_policy_document" "cost_report_bucket" {
  statement {
    sid    = "DenyNonSSLRequests"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      module.cost_report_bucket.s3_bucket_arn,
      "${module.cost_report_bucket.s3_bucket_arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
