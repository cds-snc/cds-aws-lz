output "sns_topic_arn" {
  description = "ARN of the encrypted SNS topic"
  value       = aws_sns_topic.guardrail_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.guardrail_alerts.name
}

# Cloud Brokering Monitoring Rule
output "cloud_brokering_rule_name" {
  description = "Name of the Cloud Brokering EventBridge rule"
  value       = aws_cloudwatch_event_rule.cloud_brokering_monitoring.name
}

output "cloud_brokering_rule_arn" {
  description = "ARN of the Cloud Brokering EventBridge rule"
  value       = aws_cloudwatch_event_rule.cloud_brokering_monitoring.arn
}

# KMS Monitoring Rule
output "kms_monitoring_rule_name" {
  description = "Name of the KMS EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_kms_monitoring.name
}

output "kms_monitoring_rule_arn" {
  description = "ARN of the KMS EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_kms_monitoring.arn
}

# IAM Admin Policy Detachment Monitoring Rule
output "iam_admin_demotion_rule_name" {
  description = "Name of the IAM Admin Policy Detachment EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_iam_admin_policy_monitoring_demotion.name
}

output "iam_admin_demotion_rule_arn" {
  description = "ARN of the IAM Admin Policy Detachment EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_iam_admin_policy_monitoring_demotion.arn
}

# Secrets Manager Monitoring Rule
output "secrets_manager_rule_name" {
  description = "Name of the Secrets Manager EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_secrets_manager_monitoring.name
}

output "secrets_manager_rule_arn" {
  description = "ARN of the Secrets Manager EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_secrets_manager_monitoring.arn
}

# IAM Admin Policy Attachment Monitoring Rule
output "iam_admin_promotion_rule_name" {
  description = "Name of the IAM Admin Policy Attachment EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_iam_admin_policy_monitoring_promotion.name
}

output "iam_admin_promotion_rule_arn" {
  description = "ARN of the IAM Admin Policy Attachment EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_iam_admin_policy_monitoring_promotion.arn
}

# Breakglass User Sign-In Monitoring Rule
output "breakglass_signin_rule_name" {
  description = "Name of the Breakglass User Sign-In EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_breakglass_signin_monitoring.name
}

output "breakglass_signin_rule_arn" {
  description = "ARN of the Breakglass User Sign-In EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_breakglass_signin_monitoring.arn
}

# Root User Sign-In Monitoring Rule
output "root_signin_rule_name" {
  description = "Name of the Root User Sign-In EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_root_signin_monitoring.name
}

output "root_signin_rule_arn" {
  description = "ARN of the Root User Sign-In EventBridge rule"
  value       = aws_cloudwatch_event_rule.guardrails_root_signin_monitoring.arn
}

output "email_subscription_arn" {
  description = "ARN of the email subscription (note: will show as pending until confirmed)"
  value       = aws_sns_topic_subscription.sre_team_email.arn
}
