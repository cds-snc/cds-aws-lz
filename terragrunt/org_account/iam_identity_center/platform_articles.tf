#
# Groups
#
resource "aws_identitystore_group" "articles_production_access_vpc_clientvpn" {
  display_name      = "Articles-Production-Access-VPC-ClientVPN"
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

resource "aws_identitystore_group" "articles_staging_access_vpc_clientvpn" {
  display_name      = "Articles-Staging-Access-VPC-ClientVPN"
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

#
# Accounts: assign groups and permission sets
#
locals {
  articles_permission_set_arns = [
    # GCArticles-Production
    {
      group              = aws_identitystore_group.articles_production_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
      target_id          = "472286471787"
    },
    {
      group              = aws_identitystore_group.articles_production_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
      target_id          = "472286471787"
    },
    # GCArticles-Staging       
    {
      group              = aws_identitystore_group.articles_staging_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
      target_id          = "729164266357"
    },
    {
      group              = aws_identitystore_group.articles_staging_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
      target_id          = "729164266357"
    },
    # PlatformListManager-Production
    {
      group              = aws_identitystore_group.articles_production_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
      target_id          = "762579868088"
    },
    {
      group              = aws_identitystore_group.articles_production_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
      target_id          = "762579868088"
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "articles" {
  for_each = { for perm in local.articles_permission_set_arns : perm.group.name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.principal_id
  principal_type = "GROUP"

  target_id   = each.value.target_id
  target_type = "AWS_ACCOUNT"
}
