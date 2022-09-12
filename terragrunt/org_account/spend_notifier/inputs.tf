variable "spend_notifier_hook" {
  type        = string
  description = "(Required) The identifier of the webhook to be used by the spend notifier lambda"
  sensitive   = true
}