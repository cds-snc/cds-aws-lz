variable "assume_account_id" {
  description = "(Required) The account ID to assume roles in"
  type        = string
}

variable "role_suffix" {
  description = "(Required) The suffix to use for the role name"
  type        = string
}

variable "role_name_to_assume" {
  description = "(Required) The name of the role to assume"
  type        = string
}

variable "billing_tag_key" {
  description = "(Optional, default 'CostCentre') The name of the billing tag"
  type        = string
  default     = "CostCentre"
}

variable "billing_tag_value" {
  description = "(Required) The value of the billing tag"
  type        = string
}
