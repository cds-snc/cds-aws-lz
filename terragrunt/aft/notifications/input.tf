variable "aft_notifications_hook" {
  type        = string
  description = "(Required) The webhook to post AFT Notifications to"
  sensitive   = true
}

variable "slack_notification_lambda_arn" {
  type        = string
  description = "The ARN of the Lambda function for Slack notifications"
}
