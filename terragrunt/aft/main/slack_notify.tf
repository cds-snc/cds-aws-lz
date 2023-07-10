module "aft_slack_notification" {
  source            = "github.com/cds-snc/terraform-modules//notify_slack?ref=v3.0.2"
  billing_tag_value = var.billing_code
  function_name     = "aft_slack_notification"
  project_name      = "Account Factory for Terraform"
  slack_webhook_url = var.aft_slack_webhook

  sns_topic_arns = [
    data.aws_sns_topic.aft_failure_notifications.arn,
    data.aws_sns_topic.aft_notifications.arn
  ]
}

data "aws_sns_topic" "aft_failure_notifications" {
  name = "aft-failure-notifications"
}

data "aws_sns_topic" "aft_notifications" {
  name = "aft-notifications"
}

variable "aft_slack_webhook" {
  description = "The slack webhook URL to be used by Account Factory for Terraform"
}