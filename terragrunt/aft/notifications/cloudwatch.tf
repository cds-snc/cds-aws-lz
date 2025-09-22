locals {
  aft_pipeline_log_groups = toset([
    "/aws/codebuild/aft-global-customizations-terraform",
    "/aws/codebuild/aft-account-customizations-terraform"
  ])
}

resource "aws_cloudwatch_log_metric_filter" "pipeline_failed" {
  for_each = local.aft_pipeline_log_groups

  name           = "PipelineFailed"
  pattern        = "FAILED"
  log_group_name = each.key

  metric_transformation {
    name          = "PipelineFailed-${element(split("/", each.key), 3)}"
    namespace     = "AFT"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "pipeline_failed" {
  for_each = local.aft_pipeline_log_groups

  alarm_name          = "PipelineFailed-${element(split("/", each.key), 3)}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.pipeline_failed[each.key].metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.pipeline_failed[each.key].metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_description = "AFT pipeline execution has failed"
  alarm_actions     = [aws_sns_topic.aft_cloudwatch_alarms.arn]
  ok_actions        = [aws_sns_topic.aft_cloudwatch_alarms.arn]
}

resource "aws_cloudwatch_event_rule" "new_account_created" {
  name        = "new-account-created"
  description = "Rule to capture new account creation events"
  event_pattern = jsonencode({
    "source": ["aws.controltower"],
    "detail-type": ["AWS Service Event via CloudTrail"],
    "detail": {
      "eventName": ["CreateManagedAccount"]
    }
  })
}

resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.new_account_created.name
  arn       = data.aws_sns_topic.aft_notifications.arn
}