locals {
  common_tags = {
    CostCentre = var.billing_code
    Terraform  = "true"
  }
  org_account_list_name        = "listAccountsInSandboxOUForNuke" # restricted to sandbox OU
  org_account_list_all_name    = "listAllAccounts"                # list all accounts in the org
  org_allow_policy_toggle      = "ghActionAllowPolicyToggle"
  sre_identity_audit_oidc_role = "sre_identity_audit_oidc_role"
  cbs_central_account_id       = "871282759583"
}
