#
# Dev
#
resource "aws_identitystore_group" "digital_credentials_dev_admin" {
  display_name      = "DigitalCredentials-Dev-Admin"
  description       = "Grants members administrator access to the Digital Credentials Dev account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "digital_credentials_dev_read_only" {
  display_name      = "DigitalCredentials-Dev-ReadOnly"
  description       = "Grants members read-only access to the Digital Credentials Dev account."
  identity_store_id = local.sso_identity_store_id
}
