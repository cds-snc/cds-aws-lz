# ----------------------------------------------------------------------------
# Variables specific to ssc cbrid tags compliance report 
# ----------------------------------------------------------------------------

variable "slack_webhook_url" {
  description = "Incoming webhook URL for the SRE bot / Slack."
  type        = string
  sensitive   = true
}

variable "config_rule_name" {
  description = "The Config rule to inspect."
  type        = string
  default     = "OrgConfigRule-require-ssc-cbrid-tag-wf6xls0p"
}

variable "report_prefix" {
  description = "S3 key prefix under which CSV reports are written."
  type        = string
  default     = "config-compliance-reports"
}

variable "top_n_accounts" {
  description = "How many worst-offender accounts to list in the Slack message."
  type        = number
  default     = 10
}

variable "report_retention_days" {
  description = "Days to retain report objects before automatic deletion."
  type        = number
  default     = 90
}

variable "schedule_expression" {
  description = "EventBridge schedule expression in UTC for weekly Slack alerts. Empty string disables scheduling."
  type        = string
  default     = "cron(0 6 ? * MON *)" # Mondays at 06:00 UTC (1:00am EST) 
}

variable "csv_schedule_expression" {
  description = "EventBridge schedule expression in UTC for daily CSV generation (no Slack alert). Empty string disables scheduling."
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 02:00 UTC
}

variable "lambda_image_tag" {
  description = "ECR image tag the Lambda runs. Bump when you push a new image."
  type        = string
  default     = "latest"
}