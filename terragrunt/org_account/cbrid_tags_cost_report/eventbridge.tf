resource "aws_cloudwatch_event_rule" "cost_report_monthly" {
  name                = "monthlyCostReport"
  schedule_expression = "cron(0 12 3 * ? *)"
  description         = "Trigger monthly cost report on the 3rd of each month at 12:00 UTC"

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "cost_report_monthly" {
  rule = aws_cloudwatch_event_rule.cost_report_monthly.name
  arn  = aws_lambda_function.cost_report.arn
}
