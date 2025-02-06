locals {
  common_tags = {
    CostCentre = var.billing_code
    Terraform  = "true"
  }
  sre_sechub_automation_rules_oidc_role = "sre_sechub_automation_rules_github_action"
  sre_vulnerability_report_oidc_role    = "sre_vulnerability_report_github_action"
  security_oscal_report_oidc_role       = "security_oscal_report_github_action"
}