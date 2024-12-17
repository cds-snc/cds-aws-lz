variable "assume_role_name" {
  type        = string
  description = "The name of the role to assume"
}

variable "lw_customer_id" {
  type        = string
  description = "The log workspace customer id for the sentinel forwarder"
}

variable "lw_customer_ids" {
  type        = list(string)
  description = "The log workspace customer ids for the Azure Sentinel role. This allows us to pass in multiple workspaces"
}
variable "lw_shared_key" {
  type        = string
  description = "The log workspace shared key for the sentinel forwarder"
}
