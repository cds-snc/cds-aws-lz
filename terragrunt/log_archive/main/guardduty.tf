module "guardduty_ca_central_1" {
  source = "../modules/guardduty"

  publishing_bucket_arn = module.publishing_bucket.s3_bucket_arn
  kms_key_arn           = aws_kms_key.cds_sentinel_guard_duty_key.arn

  billing_tag_value = var.billing_code
}

module "guardduty_us_east_1" {
  source = "../modules/guardduty"
  providers = {
    aws = aws.us-east-1
  }

  publishing_bucket_arn = module.publishing_bucket.s3_bucket_arn
  kms_key_arn           = aws_kms_key.cds_sentinel_guard_duty_key.arn

  billing_tag_value = var.billing_code
}

module "guardduty_us_west_2" {
  source = "../modules/guardduty"
  providers = {
    aws = aws.us-west-2
  }


  publishing_bucket_arn = module.publishing_bucket.s3_bucket_arn
  kms_key_arn           = aws_kms_key.cds_sentinel_guard_duty_key.arn

  billing_tag_value = var.billing_code
}

module "publishing_bucket" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.4//S3"


  logging = {
    target_bucket = module.publishing_log_bucket.s3_bucket_id
  }

  billing_tag_value = var.billing_code
}

module "publishing_log_bucket" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.4//S3_log_bucket"

  billing_tag_value = var.billing_code
}

data "aws_iam_policy_document" "cds_sentinel_guard_duty_logs_kms_inline" {
  statement {
    sid = "1"

    actions   = ["kms:GenerateDataKey"]
    resources = ["arn:aws:kms:ca-central-1:${var.account_id}:key/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "cds_sentinel_guard_duty_key" {
  description             = "CDS Sentinel GuardDuty KMS"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.cds_sentinel_guard_duty_logs_kms_inline.json
}

resource "aws_kms_alias" "cds_sentinel_guard_duty_key" {
  name          = "alias/guardduty-key"
  target_key_id = aws_kms_key.cds_sentinel_guard_duty_key.key_id
}