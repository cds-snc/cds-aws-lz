variable "admin_sso_role_arn" {
  type        = string
  description = "(Required) The ARN for the admin SSO role"
  sensitive   = true
}

variable "cloudformation_administration_role_name" {
  type        = string
  default     = "AWSCloudFormationStackSetAdministrationRole"
  description = "The name of the administration role. Defaults to 'AWSCloudFormationStackSetAdministrationRole'."
}

variable "cloudformation_execution_role_name" {
  type        = string
  default     = "AWSCloudFormationStackSetExecutionRole"
  description = "The name of the execution role that can assume this role. Defaults to 'AWSCloudFormationStackSetExecutionRole'."
}