#
# Accounts: assign permissions
#
locals {
  # Unified-Accounts-Staging
  unified_accounts_staging_permission_sets = [
    {
      group          = aws_identitystore_group.unified_accounts_staging_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.unified_accounts_staging_read_only_billing,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
    {
      group          = aws_identitystore_group.unified_accounts_staging_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    }
  ]
}

resource "aws_ssoadmin_account_assignment" "unified_accounts_staging" {
  for_each = { for perm in local.unified_accounts_staging_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.unified_accounts_staging_account_id
  target_type = "AWS_ACCOUNT"
}
