#
# CanadaLogin-Sandbox-Apps Account
#
resource "aws_identitystore_group" "canadalogin_sandbox_apps_admin" {
  display_name      = "CanadaLogin-Sandbox-Apps-Admin"
  description       = "Grants members administrator access to the CanadaLogin-Sandbox-Apps account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "canadalogin_sandbox_apps_read_only" {
  display_name      = "CanadaLogin-Sandbox-Apps-ReadOnly"
  description       = "Grants members read-only access to the CanadaLogin-Sandbox-Apps account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "canadalogin_sandbox_apps_read_only_billing" {
  display_name      = "CanadaLogin-Sandbox-Apps-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the CanadaLogin-Sandbox-Apps account."
  identity_store_id = local.sso_identity_store_id
}
