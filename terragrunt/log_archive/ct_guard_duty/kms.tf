locals {
  guardduty_account = "274536870005"
}

data "aws_iam_policy_document" "cds_sentinel_guard_duty_logs_kms_inline" {
  statement {
    sid = "1"

    actions   = ["kms:GenerateDataKey"]
    resources = ["arn:aws:kms:ca-central-1:${local.guardduty_account}:key/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "2"

    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.guardduty_account}:root",
        "arn:aws:iam::${local.guardduty_account}:user/terraform"
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
