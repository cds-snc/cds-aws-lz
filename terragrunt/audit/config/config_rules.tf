# Config rule auditing all resources to determine ssc_cbrid tag compliance.
#
# A single custom Lambda-backed rule handles the split logic:
#   - Platform/shared resources (IAM, VPC, ELB, KMS, S3, EBS, etc.) → 22DH only
#   - All other resource types                                        → 22DI, 21JC, or 22DJ
#
# Using a custom rule means new AWS resource types are covered automatically
# without any Terraform changes.

# ----------------------------------------------------------------------------
# Lambda zip: no external dependencies, packaged from source at plan time.
# ----------------------------------------------------------------------------
data "archive_file" "ssc_cbrid_evaluator" {
  type        = "zip"
  source_file = "${path.module}/lambda/ssc_cbrid_config_evaluator.py"
  output_path = "${path.module}/lambda/ssc_cbrid_config_evaluator.zip"
}

# ----------------------------------------------------------------------------
# IAM role for the evaluator Lambda
# ----------------------------------------------------------------------------
resource "aws_iam_role" "ssc_cbrid_evaluator" {
  name = "ssc-cbrid-config-evaluator-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssc_cbrid_evaluator_basic" {
  role       = aws_iam_role.ssc_cbrid_evaluator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ssc_cbrid_evaluator" {
  statement {
    sid     = "ConfigPutEvaluations"
    effect  = "Allow"
    actions = ["config:PutEvaluations"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ssc_cbrid_evaluator" {
  name   = "ssc-cbrid-config-put-evaluations"
  role   = aws_iam_role.ssc_cbrid_evaluator.id
  policy = data.aws_iam_policy_document.ssc_cbrid_evaluator.json
}

# ----------------------------------------------------------------------------
# Lambda function
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "ssc_cbrid_evaluator" {
  function_name    = "ssc-cbrid-config-evaluator"
  filename         = data.archive_file.ssc_cbrid_evaluator.output_path
  source_code_hash = data.archive_file.ssc_cbrid_evaluator.output_base64sha256
  role             = aws_iam_role.ssc_cbrid_evaluator.arn
  handler          = "ssc_cbrid_config_evaluator.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ssc_cbrid_evaluator" {
  name              = "/aws/lambda/${aws_lambda_function.ssc_cbrid_evaluator.function_name}"
  retention_in_days = 14

  tags = local.common_tags
}

# Allow AWS Config to invoke the Lambda
resource "aws_lambda_permission" "config_can_invoke_evaluator" {
  statement_id  = "AllowConfigToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ssc_cbrid_evaluator.function_name
  principal     = "config.amazonaws.com"
}

# ----------------------------------------------------------------------------
# Custom org-wide Config rule
# ----------------------------------------------------------------------------
resource "aws_config_organization_custom_rule" "require_ssc_cbrid" {
  name                = "require-ssc-cbrid-tag"
  description         = "Platform resources must use ssc_cbrid=22DH; all other resources must use 22DI, 21JC, or 22DJ"
  lambda_function_arn = aws_lambda_function.ssc_cbrid_evaluator.arn

  trigger_types = [
    "CONFIGURATION_ITEM_CHANGE",
    "OVERSIZED_CONFIGURATION_ITEM_CHANGE",
  ]

  # Empty = all supported resource types; new AWS types are covered automatically.
  resource_types_scope = []

  excluded_accounts = []

  depends_on = [aws_lambda_permission.config_can_invoke_evaluator]
}