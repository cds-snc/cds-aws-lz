output "sns_topic_arn" {
  description = "ARN of the encrypted SNS topic"
  value       = aws_sns_topic.cloud_brokering_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.cloud_brokering_alerts.name
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.cloud_brokering_monitoring.name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.cloud_brokering_monitoring.arn
}

output "email_subscription_arn" {
  description = "ARN of the email subscription (note: will show as pending until confirmed)"
  value       = aws_sns_topic_subscription.sre_team_email.arn
}
