### Replace this with a tf module when I build it


data "archive_file" "spend_notifier" {
  type        = "zip"
  source_file = "${path.module}/lambdas/spend_notifier/spend_notifier.js"
  output_path = "/tmp/main.py.zip"
}

resource "aws_lambda_function" "spend_notifier" {
  function_name = "spend_notifier"
  role          = aws_iam_role.spend_notifier.arn
  runtime       = "nodejs16.x"
  handler       = "app.handler"
  memory_size   = 512

  filename         = data.archive_file.spend_notifier.output_path
  source_code_hash = filebase64sha256(data.archive_file.spend_notifier.output_path)

  reserved_concurrent_executions = 0


  tracing_config {
    mode = "PassThrough"
  }

  tags = local.common_tags
}




