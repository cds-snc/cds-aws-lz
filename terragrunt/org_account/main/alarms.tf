resource "aws_sns_topic" "critical" {
  name              = "critical-issue"
  kms_master_key_id = aws_kms_key.critical_sns_cloudwatch_key.id
}

resource "aws_sns_topic" "warning" {
  name              = "warning-issue"
  kms_master_key_id = aws_kms_key.warning_sns_cloudwatch_key.id
}

# KMS Key for SNS Topics
# This is used to encrypt SNS topics for critical and warning alerts and is required by the 30 day guardrails
# Critical SNS topics KMS key
resource "aws_kms_key" "critical_sns_cloudwatch_key" {
  description = "KMS key for Critical CloudWatch SNS topics"
  policy      = data.aws_iam_policy_document.sns_cloudwatch_key_policy.json
}

# Warning SNS topics KMS key
resource "aws_kms_key" "warning_sns_cloudwatch_key" {
  description = "KMS key for Warning CloudWatch SNS topics"
  policy      = data.aws_iam_policy_document.sns_cloudwatch_key_policy.json
}

# Policy document for SNS KMS keys
data "aws_iam_policy_document" "sns_cloudwatch_key_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.org_account}:root"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}
module "alarm_actions" {
  source                = "github.com/cds-snc/terraform-modules//user_login_alarm?ref=v3.0.20"
  account_names         = ["Ops1", "Ops2"]
  log_group_name        = "aws-controltower/CloudTrailLogs"
  alarm_actions_success = [aws_sns_topic.critical.arn]
  alarm_actions_failure = [aws_sns_topic.warning.arn]
  num_attempts          = 2
}