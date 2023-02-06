variable "ou_arns" {
  type        = set(string)
  description = "The ARN of the OU to apply the guardrails to"
}

variable "identifier" {
  type        = string
  description = "The identifier of the Guardrail to enable"
}