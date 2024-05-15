#
# alpha.canada.ca Website
#
resource "aws_identitystore_group" "alpha_canada_website_production_admin" {
  display_name      = "AlphaCanadaWebsite-Production-Admin"
  description       = "Grants members administrator access to the alpha.canada.ca website Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "alpha_canada_production_read_only" {
  display_name      = "AlphaCanadaWebsite-Production-ReadOnly"
  description       = "Grants members read-only access to the alpha.canada.ca website Production account."
  identity_store_id = local.sso_identity_store_id
}

#
# Canadian Digital Service
#
resource "aws_identitystore_group" "canadian_digital_service_production_read_only" {
  display_name      = "CanadianDigitalService-Production-ReadOnly"
  description       = "Grants members read-only access to the Canadian Digital Service Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "canadian_digital_service_production_website_admin" {
  display_name      = "CanadianDigitalService-Production-Admin"
  description       = "Grants members administrator access to the Canadian Digital Service website's Production account resources."
  identity_store_id = local.sso_identity_store_id
}

#
# CdsWebsite-Production
#
resource "aws_identitystore_group" "cds_website_production_admin" {
  display_name      = "CDSWebsite-Production-Admin"
  description       = "Grants members administrator access to the Canadian Digital Service website Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "cds_website_production_read_only" {
  display_name      = "CDSWebsite-Production-ReadOnly"
  description       = "Grants members read-only access to the Canadian Digital Service website Production account."
  identity_store_id = local.sso_identity_store_id
}

#
# Website CMS
#
resource "aws_identitystore_group" "cds_website_cms_production_admin" {
  display_name      = "CDSWebsiteCMS-Production-Admin"
  description       = "Grants members administrator access to the Website CMS (Strapi) Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "cds_website_cms_production_read_only" {
  display_name      = "CDSWebsiteCMS-Production-ReadOnly"
  description       = "Grants members read-only access to the Website CMS (Strapi) Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "cds_website_cms_production_support_center_admin" {
  display_name      = "CDSWebsiteCMS-Production-SupportCenter-Admin"
  description       = "Grants members Support Center administrator access to the Website CMS (Strapi) Production account."
  identity_store_id = local.sso_identity_store_id
}
