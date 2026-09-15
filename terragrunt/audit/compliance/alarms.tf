# CloudWatch Alarms for AWS S3 CSV to Slack Lambda Function
# This file contains monitoring and alerting configuration for the Lambda function

# CloudWatch alarm for Lambda function errors
resource "aws_cloudwatch_metric_alarm" "s3_csv_to_slack_errors" {
  alarm_name          = "${local.lambda_config.name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.alarm_config.evaluation_periods
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = local.alarm_config.period
  statistic           = "Sum"
  threshold           = local.alarm_config.error_threshold
  alarm_description   = "This metric monitors ${local.lambda_config.name} lambda errors"
  alarm_actions       = [aws_sns_topic.guardrails_alerts.arn]
  ok_actions          = [aws_sns_topic.guardrails_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.s3_csv_to_slack.function_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.lambda_config.name} Errors"
  })
}

# CloudWatch alarm for Lambda function duration
resource "aws_cloudwatch_metric_alarm" "s3_csv_to_slack_duration" {
  alarm_name          = "${local.lambda_config.name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.alarm_config.evaluation_periods
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = local.alarm_config.period
  statistic           = "Average"
  threshold           = local.alarm_config.duration_threshold
  alarm_description   = "This metric monitors ${local.lambda_config.name} lambda duration"
  alarm_actions       = [aws_sns_topic.guardrails_alerts.arn]
  ok_actions          = [aws_sns_topic.guardrails_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.s3_csv_to_slack.function_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.lambda_config.name} Duration"
  })
}