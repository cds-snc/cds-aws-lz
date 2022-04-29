

# GuardDuty Detector in the Delegated admin account
resource "aws_guardduty_detector" "this" {

  enable                       = true
  finding_publishing_frequency = var.publishing_frequency

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      enable = true
    }
  }
  tags = merge(var.tags, local.common_tags)
}

# Organization GuardDuty configuration in the Delegated admin account
resource "aws_guardduty_organization_configuration" "this" {

  auto_enable = true
  detector_id = aws_guardduty_detector.this.id

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      auto_enable = true
    }
  }
}

# GuardDuty Publishing destination in the Delegated admin account
resource "aws_guardduty_publishing_destination" "pub_dest" {

  detector_id     = aws_guardduty_detector.this.id
  destination_arn = var.publishing_bucket_arn
  kms_key_arn     = var.kms_key_arn
}

locals {
  common_tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = "true"
  }
}