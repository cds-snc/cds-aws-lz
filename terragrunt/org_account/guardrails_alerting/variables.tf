
variable "sre_team_email" {
  description = "Email address for SRE team alerts"
  type        = string
  validation {
    condition     = can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$", var.sre_team_email))
    error_message = "Please provide a valid email address."
  }
  default = "sre-ifs@cds-snc.ca"
}


variable "cloud_brokering_role_arn" {
  description = "ARN of the Cloud Brokering role to monitor"
  type        = string
  default     = "arn:aws:iam::659087519042:role/SSC-CloudBrokering"
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.cloud_brokering_role_arn))
    error_message = "Please provide a valid IAM role ARN."
  }
}