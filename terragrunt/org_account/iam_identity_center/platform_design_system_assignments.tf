#
# Accounts: assign permissions
#
locals {
  # DesignSystem-Production
  design_system_production_permission_sets = [
    {
      group          = aws_identitystore_group.design_system_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.design_system_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_accessrn,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "design_system_production" {
  for_each = { for perm in local.design_system_production_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.design_system_production_account_id
  target_type = "AWS_ACCOUNT"
}
