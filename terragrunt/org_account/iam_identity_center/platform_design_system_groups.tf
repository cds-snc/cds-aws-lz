#
# Production
#
resource "aws_identitystore_group" "design_system_production_admin" {
  display_name      = "DesignSystem-Production-Admin"
  description       = "Grants members administrator access to the Design System Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "design_system_production_read_only" {
  display_name      = "DesignSystem-Production-ReadOnly"
  description       = "Grants members read-only access to the Design System Production account."
  identity_store_id = local.sso_identity_store_id
}
