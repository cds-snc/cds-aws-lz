#
# Accounts: assign permissions
#
locals {
  # GCArticles-Production
  articles_production_permission_set_arns = [
    {
      group          = aws_identitystore_group.articles_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.articles_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
  ]
  # GCArticles-Staging
  articles_staging_permission_set_arns = [
    {
      group          = aws_identitystore_group.articles_staging_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.articles_staging_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
  ]
  # PlatformListManager-Production
  list_manager_production_permission_set_arns = [
    {
      group          = aws_identitystore_group.articles_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.articles_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "articles_production" {
  for_each = { for perm in local.articles_production_permission_set_arns : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.articles_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "articles_staging" {
  for_each = { for perm in local.articles_staging_permission_set_arns : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.articles_staging_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "list_manager_production" {
  for_each = { for perm in local.list_manager_production_permission_set_arns : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.list_manager_production_account_id
  target_type = "AWS_ACCOUNT"
}

moved {
  from = aws_ssoadmin_account_assignment.articles_production["Articles-Production-Admin"]
  to   = aws_ssoadmin_account_assignment.articles_production["Articles-Production-Admin-AWSAdministratorAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.articles_production["Articles-Production-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.articles_production["Articles-Production-ReadOnly-AWSReadOnlyAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.articles_staging["Articles-Staging-Admin"]
  to   = aws_ssoadmin_account_assignment.articles_staging["Articles-Staging-Admin-AWSAdministratorAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.articles_staging["Articles-Staging-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.articles_staging["Articles-Staging-ReadOnly-AWSReadOnlyAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.list_manager_production["Articles-Production-Admin"]
  to   = aws_ssoadmin_account_assignment.list_manager_production["Articles-Production-Admin-AWSAdministratorAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.list_manager_production["Articles-Production-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.list_manager_production["Articles-Production-ReadOnly-AWSReadOnlyAccess"]
}
