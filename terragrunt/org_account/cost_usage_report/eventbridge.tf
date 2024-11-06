resource "aws_cloudwatch_event_rule" "billing_extract_tags" {
  name                = "billing_extract_tags_daily"
  schedule_expression = "cron(0 5 * * ? *)"

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "billing_extract_tags" {
  rule = aws_cloudwatch_event_rule.billing_extract_tags.name
  arn  = aws_lambda_function.billing_extract_tags.arn
}
