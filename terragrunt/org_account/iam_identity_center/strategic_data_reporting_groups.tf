#
# Strategic Data and Reporting
#
resource "aws_identitystore_group" "strategic_data_reporting_production_admin" {
  display_name      = "StrategicDataReporting-Production-Admin"
  description       = "Grants members administrator access to the Strategic Data and Reporting Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "strategic_data_reporting_production_billing_read_only" {
  display_name      = "StrategicDataReporting-Production-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Strategic Data and Reporting Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "strategic_data_reporting_production_read_only" {
  display_name      = "StrategicDataReporting-Production-ReadOnly"
  description       = "Grants members read-only access to the Strategic Data and Reporting Production account."
  identity_store_id = local.sso_identity_store_id
}
