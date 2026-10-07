# EventBridge configuration for AWS S3 CSV to Slack Lambda Function
# This file contains the EventBridge rule and target to trigger the Lambda function daily

# EventBridge rule to trigger Lambda daily at 5am PST (13:00 UTC)
# Note: PST is UTC-8, PDT is UTC-7. This uses 13:00 UTC for PST (5am PST)
# For automatic PST/PDT handling, you might want to adjust this manually twice a year
resource "aws_cloudwatch_event_rule" "daily_compliance_check" {
  name                = "${local.name_prefix}-daily-compliance-check"
  description         = "Trigger S3 CSV to Slack Lambda daily at 5am PST"
  schedule_expression = var.schedule_expression

  tags = merge(local.common_tags, {
    Name = "Daily Compliance Check Schedule"
  })
}

# EventBridge target to invoke Lambda function
resource "aws_cloudwatch_event_target" "s3_csv_to_slack_target" {
  rule      = aws_cloudwatch_event_rule.daily_compliance_check.name
  target_id = "S3CsvToSlackTarget"
  arn       = aws_lambda_function.s3_csv_to_slack.arn

  input = jsonencode({
    source      = "eventbridge"
    detail-type = "Scheduled Event"
    detail = {
      trigger = "daily-compliance-check"
    }
  })
}

# Permission for EventBridge to invoke Lambda function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_csv_to_slack.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_compliance_check.arn
}