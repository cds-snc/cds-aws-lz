#
# Production
#
resource "aws_identitystore_group" "data_lake_production_admin" {
  display_name      = "DataLake-Production-Admin"
  description       = "Grants members administrator access to the DataLake Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "data_lake_production_read_only_billing" {
  display_name      = "DataLake-Production-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the DataLake Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "data_lake_production_read_only" {
  display_name      = "DataLake-Production-ReadOnly"
  description       = "Grants members read-only access to the DataLake Production account."
  identity_store_id = local.sso_identity_store_id
}
