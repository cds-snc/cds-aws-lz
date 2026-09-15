# AWS S3 CSV to Slack Lambda Function Terraform Configuration
# This configuration creates a Lambda function that processes CSV files from S3
# and sends compliance alerts to Slack, triggered daily at 5am PST

# Archive the Lambda function code
data "archive_file" "s3_csv_to_slack_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/aws_s3_csv_to_slack"
  output_path = "${path.module}/s3_csv_to_slack.zip"
  excludes    = ["README.md", "iam-policy.json"]
}

locals {
  s3_bucket_arn = "arn:aws:s3:::${var.s3_bucket_name}"
}

# IAM role for the Lambda function
resource "aws_iam_role" "s3_csv_to_slack_lambda_role" {
  name = "${local.lambda_config.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.lambda_config.name} Role"
  })
}

# IAM policy for S3 access
resource "aws_iam_policy" "s3_csv_to_slack_s3_policy" {
  name        = "${local.lambda_config.name}-s3-policy"
  description = "IAM policy for S3 access for the CSV to Slack Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          local.s3_bucket_arn,
          "${local.s3_bucket_arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : var.s3_kms_key_arn
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.lambda_config.name} S3 Policy"
  })
}

# Attach S3 policy to Lambda role
resource "aws_iam_role_policy_attachment" "s3_csv_to_slack_s3_policy_attachment" {
  role       = aws_iam_role.s3_csv_to_slack_lambda_role.name
  policy_arn = aws_iam_policy.s3_csv_to_slack_s3_policy.arn
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "s3_csv_to_slack_lambda_basic_execution" {
  role       = aws_iam_role.s3_csv_to_slack_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "s3_csv_to_slack_logs" {
  name              = "/aws/lambda/${local.lambda_config.name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.lambda_config.name} Logs"
  })
}

# Lambda function
resource "aws_lambda_function" "s3_csv_to_slack" {
  filename      = data.archive_file.s3_csv_to_slack_zip.output_path
  function_name = local.lambda_config.name
  role          = aws_iam_role.s3_csv_to_slack_lambda_role.arn
  handler       = local.lambda_config.handler
  runtime       = local.lambda_config.runtime
  timeout       = local.lambda_config.timeout
  memory_size   = local.lambda_config.memory_size

  # Attach Lambda layer
  layers = ["arn:aws:lambda:ca-central-1:886481071419:layer:CloudGuardrailsCommonLayerPartEvidenceCollection:4"]

  source_code_hash = data.archive_file.s3_csv_to_slack_zip.output_base64sha256

  environment {
    variables = {
      S3_BUCKET         = var.s3_bucket_name
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.s3_csv_to_slack_lambda_basic_execution,
    aws_iam_role_policy_attachment.s3_csv_to_slack_s3_policy_attachment,
    aws_cloudwatch_log_group.s3_csv_to_slack_logs,
  ]

  tags = merge(local.common_tags, {
    Name = local.lambda_config.name
  })
}
