#
# Production
#
resource "aws_identitystore_group" "superset_production_admin" {
  display_name      = "Superset-Production-Admin"
  description       = "Grants members administrator access to the Superset Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "superset_production_read_only_billing" {
  display_name      = "Superset-Production-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Superset Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "superset_production_read_only" {
  display_name      = "Superset-Production-ReadOnly"
  description       = "Grants members read-only access to the Superset Production account."
  identity_store_id = local.sso_identity_store_id
}

#
# Staging
#
resource "aws_identitystore_group" "superset_staging_admin" {
  display_name      = "Superset-Staging-Admin"
  description       = "Grants members administrator access to the Superset Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "superset_staging_read_only_billing" {
  display_name      = "Superset-Staging-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Superset Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "superset_staging_read_only" {
  display_name      = "Superset-Staging-ReadOnly"
  description       = "Grants members read-only access to the Superset Staging account."
  identity_store_id = local.sso_identity_store_id
}
