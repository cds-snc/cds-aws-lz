locals {
  common_tags = {
    CostCentre = var.billing_code
    Terraform  = "true"
  }
  sre_vulnerability_report_oidc_role = "sre_vulnerability_report_github_action"
}