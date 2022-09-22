module "aft_failure_notifications" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.17//notify_slack"

  function_name     = "slack_notifier_aft"
  project_name      = "AFT"
  slack_webhook_url = var.aft_notifications_hook

  sns_topic_arns = [
    "arn:aws:sns:ca-central-1:137554749751:aft-failure-notifications",
    "arn:aws:sns:ca-central-1:137554749751:aft-notifications"
  ]

  billing_tag_value = var.billing_code

}