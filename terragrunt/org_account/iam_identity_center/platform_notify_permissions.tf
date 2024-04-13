#
# Accounts: assign permissions
#
locals {
  notify_permission_set_arns = [
    # Notification-Production
    {
      group              = aws_identitystore_group.notify_production_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
      target_id          = local.notify_production_account_id
    },
    {
      group              = aws_identitystore_group.notify_production_billing,
      permission_set_arn = data.aws_ssoadmin_permission_set.billing.arn,
      target_id          = local.notify_production_account_id
    },
    {
      group              = aws_identitystore_group.notify_production_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
      target_id          = local.notify_production_account_id
    },
    # Notification-Staging       
    {
      group              = aws_identitystore_group.notify_staging_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
      target_id          = local.notify_staging_account_id
    },
    {
      group              = aws_identitystore_group.notify_staging_billing,
      permission_set_arn = data.aws_ssoadmin_permission_set.billing.arn,
      target_id          = local.notify_staging_account_id
    },
    {
      group              = aws_identitystore_group.notify_staging_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
      target_id          = local.notify_staging_account_id
    },
    # Notification-Dev
    {
      group              = aws_identitystore_group.notify_dev_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
      target_id          = local.notify_dev_account_id
    },
    {
      group              = aws_identitystore_group.notify_dev_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
      target_id          = local.notify_dev_account_id
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "notify" {
  for_each = { for perm in local.notify_permission_set_arns : "${perm.group.display_name}-${perm.target_id}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = each.value.target_id
  target_type = "AWS_ACCOUNT"
}