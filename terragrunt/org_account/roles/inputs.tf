variable "admin_sso_role_arn" {
  type        = string
  description = "(Required) The ARN for the admin SSO role"
  sensitive   = true
}

variable "account_id" {
  type        = string
  description = "(Required) The account ID for the account"
}

variable "region" {
  type        = string
  description = "(Required) The region for the account"
}

variable "billing_code" {
  type        = string
  description = "(Required) The billing code for the account"
}