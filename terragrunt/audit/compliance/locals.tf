# Local values for computed expressions and common configuration

# Data sources for account and region information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


locals {
  # Common resource naming
  name_prefix = "guardrails-cac"

  # Account and region information
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Common tags applied to all resources
  common_tags = {
    Project     = "aws-guardrails-cac-solution"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "sre-team"
    CostCenter  = var.billing_code
  }

  # Lambda function configuration
  lambda_config = {
    name        = "${local.name_prefix}-s3-csv-to-slack"
    runtime     = "python3.12"
    timeout     = 300
    memory_size = 512
    handler     = "app.lambda_handler"
  }

  # Monitoring configuration
  alarm_config = {
    error_threshold    = 0
    duration_threshold = 240000 # 4 minutes in milliseconds
    evaluation_periods = 2
    period             = 300 # 5 minutes
  }
}