variable "cost_center_code" {
  description = "Billing code"
  type        = string
}

variable "customer_id" {
  description = "Azure log workspace customer ID"
  sensitive   = true
  type        = string
}

variable "shared_key" {
  description = "Azure log workspace shared secret"
  sensitive   = true
  type        = string
}