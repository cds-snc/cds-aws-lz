variable "assume_role_name" {
  type        = string
  description = "The name of the role to assume"
}

variable "lw_customer_ids" {
  type        = list(string)
  description = "The log workspace customer ids for the Azure Sentinel role. This allows us to pass in multiple workspaces"
}
