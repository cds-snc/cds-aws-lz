# Config rule auditing all resources to determine ssc_cbrid tag compliancy.

# Organization-wide managed rule enforcing approved ssc_cbrid tag values
resource "aws_config_organization_managed_rule" "require_ssc_cbrid" {
  name            = "require-ssc-cbrid-tag"
  description     = "Requires the ssc_cbrid tag with an approved value on all resources"
  rule_identifier = "REQUIRED_TAGS"

  # Approved CBR IDs for the ssc_cbrid tag
  input_parameters = jsonencode({
    tag1Key   = "ssc_cbrid"
    tag1Value = "22DH,22DI,21JC,22DJ" # Only allow those values for the cbr ids. Comma-separated allowed values
  })

  # Scope to specific resource types; empty means all supported types
  resource_types_scope = []

  # Accounts excluded from this rule (e.g., sandbox or test accounts)
  excluded_accounts = []
}