#
# Production 
#
resource "aws_identitystore_group" "digital_transformation_office_production_admin" {
  display_name      = "DigitalTransformationOffice-Production-Admin"
  description       = "Grants members administrator access to the Digital Transformation Office Production account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "digital_transformation_office_production_read_only" {
  display_name      = "DigitalTransformationOffice-Production-ReadOnly"
  description       = "Grants members read-only access to the Digital Transformation Office Production account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "digtal_transformation_office_production_billing_read_only" {
  display_name      = "DigitalTransformationOffice-Production-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Digital Transformation office Production account."
  identity_store_id = local.sso_identity_store_id
}


# 
# Staging
#
resource "aws_identitystore_group" "digital_transformation_office_staging_admin" {
  display_name      = "DigitalTransformationOffice-Staging-Admin"
  description       = "Grants members administrator access to the Digital Transformation Office Staging account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "digital_transformation_office_staging_read_only" {
  display_name      = "DigitalTransformationOffice-Staging-ReadOnly"
  description       = "Grants members read-only access to the Digital Transformation Office Staging account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "digtal_transformation_office_staging_billing_read_only" {
  display_name      = "DigitalTransformationOffice-Staging-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Digital Transformation office Staging account."
  identity_store_id = local.sso_identity_store_id
}