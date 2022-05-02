variable "billing_tag_key" {
  description = "(Optional, default 'CostCentre') The name of the billing tag"
  type        = string
  default     = "CostCentre"
}

variable "billing_tag_value" {
  description = "(Required) The value of the billing tag"
  type        = string
}

variable "publishing_frequency" {
  description = "Specifies the frequency of notifications sent for subsequent finding occurrences."
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "publishing_bucket_arn" {
  description = "(Required) The ARN of the S3 bucket to publish findings to"
  type        = string
}

variable "kms_key_arn" {
  description = "(Required) The KMS key to encrypt findings in the S3 bucket"
  type        = string
}

variable "tags" {
  description = <<EOF
  (Optional) Key-value map of resource tags. If configured with a provider default_tags configuration block present,
  tags with matching keys will overwrite those defined at the provider-level."
  EOF
  type        = map(string)
  default     = {}
}