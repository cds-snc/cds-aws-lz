#
# Accounts: assign permissions
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
  for_each = { for perm in local.articles_permission_set_arns : "${perm.group.display_name}-${perm.target_id}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = each.value.target_id
  target_type = "AWS_ACCOUNT"
}
