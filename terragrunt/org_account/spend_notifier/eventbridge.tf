resource "aws_cloudwatch_event_rule" "weekly_budget_spend" {
  name                = "weekly_budget_spend"
  schedule_expression = "cron(0 12 ? * SUN *)"
}

resource "aws_cloudwatch_event_target" "weekly_budget_spend" {
  rule = aws_cloudwatch_event_rule.weekly_budget_spend.arn
  arn  = aws_lambda_function.spend_notifier.arn
  input = jsonencode({
    "hook" = "${var.spend_notifier_hook}"
    }
  )
}

resource "aws_cloudwatch_event_rule" "daily_budget_spend" {
  name                = "daily_budget_spend"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_budget_spend" {
  rule = aws_cloudwatch_event_rule.daily_budget_spend.arn
  arn  = aws_lambda_function.spend_notifier.arn
  input = jsonencode({
    "hook" = "${var.spend_notifier_hook}"
  })
}