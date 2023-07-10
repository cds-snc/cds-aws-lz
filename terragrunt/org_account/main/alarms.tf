resource "aws_sns_topic" "critical" {
  name = "critical-issue"
}

resource "aws_sns_topic" "warning" {
  name = "warning-issue"
}

module "alarm_actions" {
  source                = "github.com/cds-snc/terraform-modules//user_login_alarm?ref=v3.0.2"
  account_names         = ["Ops1", "Ops2"]
  log_group_name        = "aws-controltower/CloudTrailLogs"
  alarm_actions_success = [aws_sns_topic.critical.arn]
  alarm_actions_failure = [aws_sns_topic.warning.arn]
  num_attempts          = 2
}