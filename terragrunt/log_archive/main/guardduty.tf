module "publishing_bucket" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.4//S3"

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
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.4//S3_log_bucket"

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
  bucket = module.publishing_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.cds_sentinel_guard_duty_policy.json
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

  statement {
    sid       = "2"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:root"
      ]
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

# GuardDuty Detector in the Delegated admin account
resource "aws_guardduty_detector" "detector" {

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      enable = true
    }
  }
}

resource "aws_guardduty_detector" "detector_us_east_1" {
  provider = aws.us-east-1

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      enable = true
    }
  }
}

resource "aws_guardduty_detector" "detector_us_west_2" {

  provider = aws.us-west-2

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      enable = true
    }
  }
}



# Organization GuardDuty configuration in the Delegated admin account
resource "aws_guardduty_organization_configuration" "config" {

  auto_enable = true
  detector_id = aws_guardduty_detector.detector.id

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      auto_enable = true
    }
  }
}

# Organization GuardDuty configuration in the Delegated admin account
resource "aws_guardduty_organization_configuration" "config_us_east_1" {

  provider = aws.us-east-1

  auto_enable = true
  detector_id = aws_guardduty_detector.detector_us_east_1.id

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      auto_enable = true
    }
  }
}
# Organization GuardDuty configuration in the Delegated admin account
resource "aws_guardduty_organization_configuration" "config_us_west_2" {

  provider = aws.us-west-2

  auto_enable = true
  detector_id = aws_guardduty_detector.detector_us_west_2.id

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      auto_enable = true
    }
  }
}

# GuardDuty Publishing destination in the Delegated admin account
resource "aws_guardduty_publishing_destination" "pub_dest" {

  detector_id     = aws_guardduty_detector.detector.id
  destination_arn = module.publishing_bucket.s3_bucket_arn
  kms_key_arn     = aws_kms_key.cds_sentinel_guard_duty_key.arn
}

locals {
  account_ids = [
    "137554749751", # AFT-Manamgement
    "886481071419", # Audit
    "034163289675", # ct-test-account
    "659087519042"  # Org Account must be enabled in master account first
  ]
}

resource "aws_guardduty_member" "members" {

  count = length(local.account_ids)

  detector_id = aws_guardduty_detector.detector.id
  invite      = true

  account_id                 = local.account_ids[count.index]
  disable_email_notification = true
  email                      = "aws-cloud-pb-ct+tf@cds-snc.ca"

  lifecycle {
    ignore_changes = [
      email
    ]
  }
}


resource "aws_guardduty_member" "members_us_east_1" {

  count = length(local.account_ids)

  provider = aws.us-east-1

  detector_id = aws_guardduty_detector.detector_us_east_1.id
  invite      = true

  account_id                 = local.account_ids[count.index]
  disable_email_notification = true
  email                      = "aws-cloud-pb-ct+tf@cds-snc.ca"

  lifecycle {
    ignore_changes = [
      email
    ]
  }
}


resource "aws_guardduty_member" "members_us_west_2" {

  count = length(local.account_ids)

  provider = aws.us-west-2

  detector_id = aws_guardduty_detector.detector_us_west_2.id
  invite      = true

  account_id                 = local.account_ids[count.index]
  disable_email_notification = true
  email                      = "aws-cloud-pb-ct+tf@cds-snc.ca"

  lifecycle {
    ignore_changes = [
      email
    ]
  }
}