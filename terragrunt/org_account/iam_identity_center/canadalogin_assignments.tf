#
# Accounts: assign permissions
#
locals {
  # CanadaLogin-Sandbox-Apps
  canadalogin_sandbox_apps_permission_sets = [
    {
      group          = aws_identitystore_group.canadalogin_sandbox_apps_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.canadalogin_sandbox_apps_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
    {
      group          = aws_identitystore_group.canadalogin_sandbox_apps_read_only_billing,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "canadalogin_sandbox_apps" {
  for_each = { for perm in local.canadalogin_sandbox_apps_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.canadalogin_sandbox_apps_account_id
  target_type = "AWS_ACCOUNT"
}
