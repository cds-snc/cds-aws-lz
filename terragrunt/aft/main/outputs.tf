output "slack_notification_lambda_arn" {
  value       = module.aft_slack_notification.lambda_arn
  description = "The ARN of the Lambda function that sends notifications to Slack"
}