module "aft_failure_notifications" {
  source = "github.com/cds-snc/terraform-modules//notify_slack?ref=v9.4.11"

  function_name     = "slack_notifier_aft"
  project_name      = "AFT"
  slack_webhook_url = var.aft_notifications_hook

  sns_topic_arns = [
    "arn:aws:sns:ca-central-1:137554749751:aft-failure-notifications"
  ]

  billing_tag_value = var.billing_code

}

data "aws_sns_topic" "aft_failure_notifications" {
  name = "aft-failure-notifications"
}

resource "aws_sns_topic_subscription" "aft_failure_notifications" {
  topic_arn = data.aws_sns_topic.aft_failure_notifications.arn
  protocol  = "lambda"
  endpoint  = module.aft_failure_notifications.lambda_arn
}

resource "aws_sns_topic_subscription" "slack_notification" {
  topic_arn = data.aws_sns_topic.aft_notifications.arn
  protocol  = "lambda"
  endpoint  = var.slack_notification_lambda_arn
}
