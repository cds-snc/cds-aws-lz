data "aws_caller_identity" "current" {}


# SNS Topic with AWS Managed KMS Encryption
resource "aws_sns_topic" "cloud_brokering_alerts" {
  name = "cloud-brokering-security-alerts"

  # Use AWS managed KMS key for SNS
  kms_master_key_id = "alias/aws/sns"

  # Additional security settings
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
    }
  })
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "cloud_brokering_alerts" {
  arn = aws_sns_topic.cloud_brokering_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cloud_brokering_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AccessPolicy"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "SNS:Publish",
          "SNS:RemovePermission",
          "SNS:SetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:AddPermission",
          "SNS:Subscribe",
        ]
        Resource = aws_sns_topic.cloud_brokering_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "sre_team_email" {
  topic_arn = aws_sns_topic.cloud_brokering_alerts.arn
  protocol  = "email"
  endpoint  = var.sre_team_email

  # Optional: Set delivery policy for email
  delivery_policy = jsonencode({
    "healthyRetryPolicy" = {
      "minDelayTarget"     = 20
      "maxDelayTarget"     = 20
      "numRetries"         = 3
      "numMaxDelayRetries" = 0
      "numMinDelayRetries" = 0
      "numNoDelayRetries"  = 0
      "backoffFunction"    = "linear"
    }
  })
}