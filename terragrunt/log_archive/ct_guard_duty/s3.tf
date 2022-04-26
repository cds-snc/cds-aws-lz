###
# AWS S3 bucket - GuardDuty logs for Sentinel
###

module "guard_duty" {
  source      = "github.com/cds-snc/terraform-modules?ref=v2.0.3//S3"
  bucket_name = "cds-sentinel-283582579564-guard-duty"
  versioning = {
    enabled = true
  }
  lifecycle_rule = [{
    enabled = true
    expiration = {
      days = 14
    }
  }]
  billing_tag_value = var.billing_code
}

data "aws_iam_policy_document" "cds_sentinel_guard_duty_policy" {
  statement {
    sid = "1"

    actions   = ["s3:GetBucketLocation"]
    resources = [module.guard_duty.s3_bucket_arn]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "2"

    actions   = ["s3:PutObject"]
    resources = ["${module.guard_duty.s3_bucket_arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "cds_sentinel_guard_duty_policy" {
  bucket     = module.guard_duty.s3_bucket_id
  policy     = data.aws_iam_policy_document.cds_sentinel_guard_duty_policy.json
  depends_on = [module.guard_duty]
}