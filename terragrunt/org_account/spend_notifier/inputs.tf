variable "daily_spend_notifier_hook" {
  type        = string
  description = "(Required) The identifier of the webhook to be used by the spend notifier lambda daily"
  sensitive   = true
}

variable "weekly_spend_notifier_hook" {
  type        = string
  description = "(Required) The identifier of the webhook to be used by the spend notifier lambda weekly"
  sensitive   = true
}