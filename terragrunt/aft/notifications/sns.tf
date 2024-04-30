resource "aws_sns_topic" "aft_cloudwatch_alarms" {
  name              = "aft-cloudwatch-alarms"
  kms_master_key_id = aws_kms_key.aft_cloudwatch_alarms.id

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

resource "aws_sns_topic_subscription" "aft_cloudwatch_alarms_slack" {
  topic_arn = aws_sns_topic.cloudwatch_alarms.arn
  protocol  = "https"
  endpoint  = var.aft_notifications_hook
}

resource "aws_kms_key" "aft_cloudwatch_alarms" {
  # checkov:skip=CKV_AWS_7: key rotation not required for CloudWatch SNS topic's messages
  description = "KMS key for AFT CloudWatch Alarm SNS topic"
  policy      = data.aws_iam_policy_document.aft_cloudwatch_alarms.json

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

data "aws_iam_policy_document" "aft_cloudwatch_alarms" {
  # checkov:skip=CKV_AWS_109: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  # checkov:skip=CKV_AWS_111: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
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