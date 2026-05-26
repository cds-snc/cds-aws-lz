# =============================================================================
# SSC CBRid tag compliance report
#
# Lambda that queries the org Config aggregator (created in aggregator.tf) for
# the require-ssc-cbrid-tag rule, counts compliant/non-compliant resources per
# account, writes a CSV report to a private S3 bucket, and posts a summary to
# the SRE bot / Slack. The lambda is triggered Monday morning by an EventBridge
# rule.
#
# =============================================================================

# ----------------------------------------------------------------------------
# S3 bucket for the CSV reports
# ----------------------------------------------------------------------------
module "report_bucket" {
  source = "github.com/cds-snc/terraform-modules//S3?ref=v11.3.0"

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
  source = "github.com/cds-snc/terraform-modules//lambda_schedule?ref=v11.3.0"

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
  }
}