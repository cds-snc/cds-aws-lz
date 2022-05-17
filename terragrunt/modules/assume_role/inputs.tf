variable "org_account" {
  type        = string
  description = "(Required) The account number of the organization allowed to assume the role"
}

variable "role_name" {
  type        = string
  description = "(Required) The name of the role allowed to assume this role"
}

variable "assume_policy_name" {
  type        = string
  description = "(Required) The name of the policy"
}

variable "org_account_role_name" {
  type        = string
  description = "(Required) The name of the role allowed to assume this role"
}

variable "billing_tag_key" {
  default     = "CostCentre"
  type        = string
  description = "The key of the tag to be used for billing purposes"
}

variable "billing_tag_value" {
  type        = string
  description = "The value of the tag to be used for billing purposes"
}