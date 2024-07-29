#
# Production
#
resource "aws_identitystore_group" "forms_production_admin" {
  display_name      = "Forms-Production-Admin"
  description       = "Grants members administrator access to the GC Forms Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "forms_production_athena_query_access" {
  display_name      = "Forms-Production-Athena-Query-Access"
  description       = "Grants members access to run Athena queries in the GC Forms Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "forms_production_rds_query_access" {
  display_name      = "Forms-Production-RDS-Query-Access"
  description       = "Grants members access to the RDS query editor in the GC Forms Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "forms_production_read_only" {
  display_name      = "Forms-Production-ReadOnly"
  description       = "Grants members read-only access to the GC Forms Production account."
  identity_store_id = local.sso_identity_store_id
}

#
# Staging
#
resource "aws_identitystore_group" "forms_staging_admin" {
  display_name      = "Forms-Staging-Admin"
  description       = "Grants members administrator access to the GC Forms Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "forms_staging_athena_query_access" {
  display_name      = "Forms-Staging-Athena-Query-Access"
  description       = "Grants members access to run Athena queries in the GC Forms Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "forms_staging_rds_query_access" {
  display_name      = "Forms-Staging-RDS-Query-Access"
  description       = "Grants members access to the RDS query editor in the GC Forms Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "forms_staging_read_only" {
  display_name      = "Forms-Staging-ReadOnly"
  description       = "Grants members read-only access to the GC Forms Staging account."
  identity_store_id = local.sso_identity_store_id
}
