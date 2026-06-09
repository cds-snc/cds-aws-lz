variable "cost_report_slack_webhook_url" {
  type        = string
  description = "(Required) The full Slack webhook URL to post the monthly cost report to"
  sensitive   = true
}

variable "cost_report_po_numbers" {
  type        = string
  description = "(Required) JSON map of ssc_cbrid tag values to PO numbers, e.g. '{\"22DH\":\"2BSCS32244\"}'"
  sensitive   = true
  default     = "{}"
}
