resource "aws_identitystore_group" "awsops" {
  display_name      = "AWSOps"
  description       = "Grants members access to the AWS Operations group."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "awsops_read_only" {
  display_name      = "AWSOpsReadonly"
  description       = "Grants members access to the AWS Operations group with read-only permissions."
  identity_store_id = local.sso_identity_store_id
}
