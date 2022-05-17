variable "billing_tag_key" {
  default     = "CostCentre"
  type        = string
  description = "The key of the tag to be used for billing purposes"
}

variable "billing_tag_value" {
  type        = string
  description = "The value of the tag to be used for billing purposes"
}

variable "assume_role_name" {
  type        = string
  description = "The name of the role assuming into the account"
}

variable "account_id" {
  type        = string
  description = "The id of the account we want to assume into"
}

variable "name_of_role_to_assume" {
  type        = string
  description = "The name name of the role we want to assume"
}