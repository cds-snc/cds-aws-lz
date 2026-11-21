# SNS Topic Configuration for AWS Guardrails CAC Solution
# This file contains the SNS topic for CloudWatch alarm notifications

# SNS topic for CloudWatch alarm notifications
resource "aws_sns_topic" "guardrails_alerts" {
  name         = "${local.name_prefix}-alerts"
  display_name = "AWS Guardrails CAC Solution Alerts"

  # Enable KMS encryption with AWS managed key
  kms_master_key_id = "alias/aws/sns"

  # Message delivery retry policy
  delivery_policy = jsonencode({
    "http" = {
      "defaultHealthyRetryPolicy" = {
        "minDelayTarget"     = 20
        "maxDelayTarget"     = 20
        "numRetries"         = 3
        "numMaxDelayRetries" = 0
        "numMinDelayRetries" = 0
        "numNoDelayRetries"  = 0
        "backoffFunction"    = "linear"
      }
      "disableSubscriptionOverrides" = false
      "defaultThrottlePolicy" = {
        "maxReceivesPerSecond" = 1
      }
    }
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix} Alerts Topic"
    Type = "notification"
  })
}

# SNS topic policy to allow CloudWatch to publish messages
resource "aws_sns_topic_policy" "guardrails_alerts_policy" {
  arn = aws_sns_topic.guardrails_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-alerts-policy"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.guardrails_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}