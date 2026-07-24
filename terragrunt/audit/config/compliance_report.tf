# =============================================================================
# SSC CBRid tag compliance report
#
# Lambda that queries the org Config aggregator (created in aggregator.tf) for
# the require-ssc-cbrid-tag rule, counts compliant/non-compliant resources per
# account, and writes a CSV report to a private S3 bucket. Additionally, a
# summary is posted to the SRE bot / Slack once per week. The lambda is
# triggered daily by an EventBridge rule (CSV only), and again on Monday with
# Slack alert enabled.
#
# =============================================================================

# ----------------------------------------------------------------------------
# S3 bucket for the CSV reports
# ----------------------------------------------------------------------------
module "report_bucket" {
  source = "github.com/cds-snc/terraform-modules//S3?ref=v11.4.4"

  bucket_name = "cds-ssc-cbrid-compliance-reports"

  billing_tag_value = var.billing_code

  # Private + locked down (these are the module defaults, set explicitly).
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Expire old reports.
  lifecycle_rule = [
    {
      id      = "expire-old-reports"
      enabled = true
      prefix  = "${var.report_prefix}/"
      expiration = {
        days = var.report_retention_days
      }
    }
  ]

  tags = local.common_tags
}

# ----------------------------------------------------------------------------
# IAM policy: AWS Config aggregate reads + Organizations list.
# (S3 write is granted by the lambda_schedule module via s3_arn_write_path.)
# ----------------------------------------------------------------------------
data "aws_iam_policy_document" "report_extra" {
  statement {
    sid    = "ConfigAggregatorRead"
    effect = "Allow"
    actions = [
      "config:GetAggregateConfigRuleComplianceSummary",
      "config:GetAggregateComplianceDetailsByConfigRule",
      "config:BatchGetAggregateResourceConfig",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ListAccounts"
    effect    = "Allow"
    actions   = ["organizations:ListAccounts"]
    resources = ["*"]
  }
}

# ----------------------------------------------------------------------------
# Lambda (container image) + ECR repo + EventBridge schedule, all from the
# CDS lambda_schedule module.
# ----------------------------------------------------------------------------
module "compliance_report" {
  source = "github.com/cds-snc/terraform-modules//lambda_schedule?ref=v11.4.4"

  lambda_name       = "ssc-cbrid-compliance-report"
  billing_tag_value = var.billing_code

  # ECR: let the module create the repository; build & push the image to it
  # image_tag defaults to "latest".
  create_ecr_repository = true
  lambda_image_tag      = var.lambda_image_tag

  lambda_timeout = 120
  lambda_memory  = 256

  # Run weekly: Monday 06:00 UTC = Monday 01:00 EST.
  lambda_schedule_expression = var.schedule_expression

  # Grant write access to the report prefix in the bucket.
  s3_arn_write_path = "${module.report_bucket.s3_bucket_arn}/${var.report_prefix}/*"

  # Extra IAM (Config reads + Organizations).
  lambda_policies = [data.aws_iam_policy_document.report_extra.json]

  lambda_environment_variables = {
    CONFIG_AGGREGATOR_NAME = aws_config_configuration_aggregator.organization.name
    CONFIG_RULE_NAME       = var.config_rule_name
    CONFIG_REGION          = var.region
    SLACK_WEBHOOK_URL      = var.slack_webhook_url
    S3_BUCKET              = module.report_bucket.s3_bucket_id
    S3_PREFIX              = var.report_prefix
    TOP_N_ACCOUNTS         = tostring(var.top_n_accounts)
    SEND_SLACK_ALERT       = "true"
  }
}

# ----------------------------------------------------------------------------
# Additional daily EventBridge rule: CSV-only, no Slack alert
# Runs before the weekly alert to ensure fresh CSV is available
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "compliance_report_daily" {
  count               = var.csv_schedule_expression != "" ? 1 : 0
  name                = "ssc-cbrid-compliance-report-daily"
  description         = "Trigger SSC CBRID compliance report Lambda daily (CSV only, no Slack)"
  schedule_expression = var.csv_schedule_expression
  tags                = local.common_tags
}

resource "aws_cloudwatch_event_target" "compliance_report_daily" {
  count     = var.csv_schedule_expression != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.compliance_report_daily[0].name
  target_id = "ssc-cbrid-compliance-report-lambda"
  arn       = module.compliance_report.lambda_function_arn
  role_arn  = module.compliance_report.lambda_function_role_arn

  input = jsonencode({
    "send_slack_alert" = false
  })
}