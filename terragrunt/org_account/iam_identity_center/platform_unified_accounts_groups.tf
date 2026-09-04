#
# Staging
#
resource "aws_identitystore_group" "platform_unified_accounts_staging_admin" {
  display_name      = "Platform-Unified-Accounts-Staging-Admin"
  description       = "Grants members administrator access to the Platform Unified Accounts Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "platform_unified_accounts_staging_vpc_clientvpn" {
  display_name      = "Platform-Unified-Accounts-Staging-VPC-ClientVPN-Access"
  description       = "Grants members access to the Platform Unified Accounts Staging Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "platform_unified_accounts_staging_read_only_billing" {
  display_name      = "Platform-Unified-Accounts-Staging-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Platform Unified Accounts Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "platform_unified_accounts_staging_read_only" {
  display_name      = "Platform-Unified-Accounts-Staging-ReadOnly"
  description       = "Grants members read-only access to the Platform Unified Accounts Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "platform_unified_accounts_staging_athena_query_access" {
  display_name      = "Platform-Unified-Accounts-Staging-Athena-Query-Access"
  description       = "Grants members access to run Athena queries in the Platform Unified Accounts Staging account."
  identity_store_id = local.sso_identity_store_id
}


#
# Production
#
resource "aws_identitystore_group" "platform_unified_accounts_production_admin" {
  display_name      = "Platform-Unified-Accounts-Production-Admin"
  description       = "Grants members administrator access to the Platform Unified Accounts Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "platform_unified_accounts_production_vpc_clientvpn" {
  display_name      = "Platform-Unified-Accounts-Production-VPC-ClientVPN-Access"
  description       = "Grants members access to the Platform Unified Accounts Production Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "platform_unified_accounts_production_read_only_billing" {
  display_name      = "Platform-Unified-Accounts-Production-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Platform Unified Accounts Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "platform_unified_accounts_production_read_only" {
  display_name      = "Platform-Unified-Accounts-Production-ReadOnly"
  description       = "Grants members read-only access to the Platform Unified Accounts Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "platform_unified_accounts_production_athena_query_access" {
  display_name      = "Platform-Unified-Accounts-Production-Athena-Query-Access"
  description       = "Grants members access to run Athena queries in the Platform Unified Accounts Production account."
  identity_store_id = local.sso_identity_store_id
}