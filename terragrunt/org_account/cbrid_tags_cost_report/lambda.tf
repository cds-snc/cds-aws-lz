data "archive_file" "cost_report" {
  type        = "zip"
  source_file = "${path.module}/lambdas/cost_report/main.py"
  output_path = "/tmp/cost_report.zip"
}

resource "aws_lambda_function" "cost_report" {
  function_name = "cbrid_tags_cost_report"
  role          = aws_iam_role.cost_report.arn
  runtime       = "python3.11"
  handler       = "main.handler"
  memory_size   = 512
  timeout       = 300

  filename         = data.archive_file.cost_report.output_path
  source_code_hash = filebase64sha256(data.archive_file.cost_report.output_path)

  environment {
    variables = {
      TARGET_BUCKET                 = module.cost_report_bucket.s3_bucket_id
      COST_REPORT_SLACK_WEBHOOK_URL = var.cost_report_slack_webhook_url
      COST_REPORT_PO_NUMBERS        = var.cost_report_po_numbers
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "cost_report_monthly" {
  statement_id  = "AllowMonthlyCostReport"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_report.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_report_monthly.arn
}

resource "aws_cloudwatch_log_group" "cost_report" {
  #checkov:skip=CKV_AWS_158:We trust the AWS provided keys
  name              = "/aws/lambda/${aws_lambda_function.cost_report.function_name}"
  retention_in_days = "14"
  tags              = local.common_tags
}
