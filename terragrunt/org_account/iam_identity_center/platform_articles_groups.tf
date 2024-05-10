#
# Production
#
resource "aws_identitystore_group" "articles_production_access_vpc_clientvpn" {
  display_name      = "Articles-Production-VPC-ClientVPN-Access"
  description       = "Grants members access to the GC Articles Production Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "articles_production_admin" {
  display_name      = "Articles-Production-Admin"
  description       = "Grants members administrator access to the GC Articles Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "articles_production_read_only" {
  display_name      = "Articles-Production-ReadOnly"
  description       = "Grants members read-only access to the GC Articles Production account."
  identity_store_id = local.sso_identity_store_id
}

#
# Staging
#
resource "aws_identitystore_group" "articles_staging_access_vpc_clientvpn" {
  display_name      = "Articles-Staging-VPC-ClientVPN-Access"
  description       = "Grants members access to the GC Articles Staging Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "articles_staging_admin" {
  display_name      = "Articles-Staging-Admin"
  description       = "Grants members administrator access to the GC Articles Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "articles_staging_read_only" {
  display_name      = "Articles-Staging-ReadOnly"
  description       = "Grants members read-only access to the GC Articles Staging account."
  identity_store_id = local.sso_identity_store_id
}
