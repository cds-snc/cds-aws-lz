

resource "aws_guardduty_organization_admin_account" "gd_admin_ca_central_1" {
  admin_account_id = local.admin_account
}

resource "aws_guardduty_organization_admin_account" "gd_admin_us_east_1" {
  provider         = aws.us-east-1
  admin_account_id = local.admin_account
}

resource "aws_guardduty_organization_admin_account" "gd_admin_us_west_2" {
  provider         = aws.us-west-2
  admin_account_id = local.admin_account
}

module "gd_org_detector" {
  source = "../../modules/guardduty_detectors"
  providers = {
    aws.ca_central_1 = aws
    aws.us_east_1    = aws.us-east-1
    aws.us_west_2    = aws.us-west-2
  }
}

module "gd_log_archive_detector" {
  source = "../../modules/guardduty_detectors"
  providers = {
    aws.ca_central_1 = aws.log_archive
    aws.us_east_1    = aws.log_archive_us_east_1
    aws.us_west_2    = aws.log_archive_us_west_2
  }
}

module "gd_audit_detector" {
  source = "../../modules/guardduty_detectors"
  providers = {
    aws.ca_central_1 = aws.audit_log
    aws.us_east_1    = aws.audit_log_us_east_1
    aws.us_west_2    = aws.audit_log_us_west_2
  }
}

module "gd_aft_management_detector" {
  source = "../../modules/guardduty_detectors"
  providers = {
    aws.ca_central_1 = aws.aft_management
    aws.us_east_1    = aws.aft_management_us_east_1
    aws.us_west_2    = aws.aft_management_us_west_2
  }
}

# Organization GuardDuty configuration in the Delegated admin account
resource "aws_guardduty_organization_configuration" "config" {

  provider    = aws.log_archive
  auto_enable = true
  detector_id = module.gd_log_archive_detector.ca_central_1_detector_id

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      auto_enable = true
    }
  }
}

# Organization GuardDuty configuration in the Delegated admin account
resource "aws_guardduty_organization_configuration" "config_us_east_1" {

  provider = aws.log_archive_us_east_1

  auto_enable = true
  detector_id = module.gd_log_archive_detector.us_east_1_detector_id

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      auto_enable = true
    }
  }
}

# Organization GuardDuty configuration in the Delegated admin account
resource "aws_guardduty_organization_configuration" "config_us_west_2" {

  provider = aws.log_archive_us_west_2

  auto_enable = true
  detector_id = module.gd_log_archive_detector.us_west_2_detector_id

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      auto_enable = true
    }
  }
}


module "publishing_bucket" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.2//S3"

  providers = {
    aws = aws.log_archive
  }

  versioning = {
    enabled = true
  }

  lifecycle_rule = [{
    enabled = true
    expiration = {
      days = 14
    }
  }]

  logging = {
    target_bucket = module.publishing_log_bucket.s3_bucket_id
  }

  billing_tag_value = var.billing_code
}

module "publishing_log_bucket" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.2//S3_log_bucket"

  providers = {
    aws = aws.log_archive
  }

  billing_tag_value = var.billing_code
}

data "aws_iam_policy_document" "cds_sentinel_guard_duty_policy" {
  statement {
    sid = "1"

    actions   = ["s3:GetBucketLocation"]
    resources = [module.publishing_bucket.s3_bucket_arn]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "2"

    actions   = ["s3:PutObject"]
    resources = ["${module.publishing_bucket.s3_bucket_arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "cds_sentinel_guard_duty_policy" {

  provider = aws.log_archive
  bucket   = module.publishing_bucket.s3_bucket_id
  policy   = data.aws_iam_policy_document.cds_sentinel_guard_duty_policy.json
}


data "aws_caller_identity" "log_archive" {
  provider = aws.log_archive
}

data "aws_iam_policy_document" "cds_sentinel_guard_duty_logs_kms_inline" {
  statement {
    sid = "1"

    actions = ["kms:GenerateDataKey"]
    resources = [
      "arn:aws:kms:ca-central-1:${data.aws_caller_identity.log_archive.account_id}:key/*",
      "arn:aws:kms:us-east-1:${data.aws_caller_identity.log_archive.account_id}:key/*",
      "arn:aws:kms:us-west-2:${data.aws_caller_identity.log_archive.account_id}:key/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid       = "2"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.log_archive.account_id}:root"
      ]
    }
  }
}

resource "aws_kms_key" "cds_sentinel_guard_duty_key" {
  provider                = aws.log_archive
  description             = "CDS Sentinel GuardDuty KMS"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.cds_sentinel_guard_duty_logs_kms_inline.json
}

resource "aws_kms_alias" "cds_sentinel_guard_duty_key" {
  provider      = aws.log_archive
  name          = "alias/guardduty-key"
  target_key_id = aws_kms_key.cds_sentinel_guard_duty_key.key_id
}


# Organization GuardDuty configuration in the Delegated admin account

# GuardDuty Publishing destination in the Delegated admin account
resource "aws_guardduty_publishing_destination" "pub_dest" {

  provider = aws.log_archive

  detector_id     = module.gd_log_archive_detector.ca_central_1_detector_id
  destination_arn = module.publishing_bucket.s3_bucket_arn
  kms_key_arn     = aws_kms_key.cds_sentinel_guard_duty_key.arn
}

resource "aws_guardduty_publishing_destination" "pub_dest_us_east_1" {

  provider = aws.log_archive_us_east_1

  detector_id     = module.gd_log_archive_detector.us_east_1_detector_id
  destination_arn = module.publishing_bucket.s3_bucket_arn
  kms_key_arn     = aws_kms_key.cds_sentinel_guard_duty_key.arn
}

resource "aws_guardduty_publishing_destination" "pub_dest_us_west_2" {

  provider = aws.log_archive_us_west_2

  detector_id     = module.gd_log_archive_detector.us_west_2_detector_id
  destination_arn = module.publishing_bucket.s3_bucket_arn
  kms_key_arn     = aws_kms_key.cds_sentinel_guard_duty_key.arn
}