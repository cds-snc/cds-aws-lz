#
# Staging
#
resource "aws_identitystore_group" "unified_accounts_staging_admin" {
  display_name      = "Unified-Accounts-Staging-Admin"
  description       = "Grants members administrator access to the Unified Accounts Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "unified_accounts_staging_vpc_clientvpn" {
  display_name      = "Unified-Accounts-Staging-VPC-ClientVPN-Access"
  description       = "Grants members access to the Unified Accounts Staging Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "unified_accounts_staging_read_only_billing" {
  display_name      = "Unified-Accounts-Staging-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Unified Accounts Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "unified_accounts_staging_read_only" {
  display_name      = "Unified-Accounts-Staging-ReadOnly"
  description       = "Grants members read-only access to the Unified Accounts Staging account."
  identity_store_id = local.sso_identity_store_id
}
