data "archive_file" "billing_extract_tags" {
  type        = "zip"
  source_file = "${path.module}/lambdas/billing_extract_tags/main.py"
  output_path = "/tmp/main.py.zip"
}

resource "aws_lambda_function" "billing_extract_tags" {
  function_name = "billing_extract_tags"
  role          = aws_iam_role.billing_extract_tags.arn
  runtime       = "python3.11"
  handler       = "main.handler"
  memory_size   = 1024
  timeout       = 30

  filename         = data.archive_file.billing_extract_tags.output_path
  source_code_hash = filebase64sha256(data.archive_file.billing_extract_tags.output_path)

  environment {
    variables = {
      TARGET_BUCKET = local.data_lake_raw_s3_bucket_arn
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "billing_extract_tags" {
  statement_id  = "AllowBillingExtractTagsDaily"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.billing_extract_tags.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.billing_extract_tags.arn
}

resource "aws_cloudwatch_log_group" "billing_extract_tags" {
  #checkov:skip=CKV_AWS_158:We trust the AWS provided keys
  name              = "/aws/lambda/${aws_lambda_function.billing_extract_tags.function_name}"
  retention_in_days = "14"
  tags              = local.common_tags
}
