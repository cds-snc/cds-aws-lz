# Outputs for AWS S3 CSV to Slack Lambda Function

# Lambda function outputs (from lambda.tf)
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.s3_csv_to_slack.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.s3_csv_to_slack.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.s3_csv_to_slack.invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.s3_csv_to_slack_lambda_role.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.s3_csv_to_slack_logs.name
}

# EventBridge outputs (from eventbridge.tf)
output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily_compliance_check.name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily_compliance_check.arn
}

output "schedule_expression" {
  description = "Cron expression for the scheduled execution"
  value       = aws_cloudwatch_event_rule.daily_compliance_check.schedule_expression
}

# CloudWatch Alarms outputs (from alarms.tf)
output "error_alarm_name" {
  description = "Name of the Lambda errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.s3_csv_to_slack_errors.alarm_name
}

output "duration_alarm_name" {
  description = "Name of the Lambda duration CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.s3_csv_to_slack_duration.alarm_name
}

# SNS Topic outputs (from sns.tf)
output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  value       = aws_sns_topic.guardrails_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alarm notifications"
  value       = aws_sns_topic.guardrails_alerts.name
}
