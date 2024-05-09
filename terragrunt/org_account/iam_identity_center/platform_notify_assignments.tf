#
# Accounts: assign permissions
#
locals {
  # Notification-Production
  notify_production_permission_set_arns = [
    {
      group              = aws_identitystore_group.notify_production_access_ecs_blazer,
      permission_set_arn = aws_ssoadmin_permission_set.notify_access_ecs_blazer.arn,
    },
    {
      group              = aws_identitystore_group.notify_production_access_quicksight,
      permission_set_arn = aws_ssoadmin_permission_set.access_quicksight.arn,
    },
    {
      group              = aws_identitystore_group.notify_production_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
    },
    {
      group              = aws_identitystore_group.notify_production_admin_pinpoint_sms,
      permission_set_arn = aws_ssoadmin_permission_set.admin_pointpoint_sms.arn,
    },
    {
      group              = aws_identitystore_group.notify_production_admin_s3_website_assets,
      permission_set_arn = aws_ssoadmin_permission_set.admin_s3_website_assets.arn,
    },
    {
      group              = aws_identitystore_group.notify_production_admin_support_center,
      permission_set_arn = aws_ssoadmin_permission_set.admin_support_center.arn,
    },
    {
      group              = aws_identitystore_group.notify_production_billing,
      permission_set_arn = data.aws_ssoadmin_permission_set.billing.arn,
    },
    {
      group              = aws_identitystore_group.notify_production_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
    }
  ]
  # Notification-Staging
  notify_staging_permission_set_arns = [
    {
      group              = aws_identitystore_group.notify_staging_access_ecs_blazer,
      permission_set_arn = aws_ssoadmin_permission_set.notify_access_ecs_blazer.arn,
    },
    {
      group              = aws_identitystore_group.notify_staging_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
    },
    {
      group              = aws_identitystore_group.notify_staging_admin_pinpoint_sms,
      permission_set_arn = aws_ssoadmin_permission_set.admin_pointpoint_sms.arn,
    },
    {
      group              = aws_identitystore_group.notify_staging_admin_s3_website_assets,
      permission_set_arn = aws_ssoadmin_permission_set.admin_s3_website_assets.arn,
    },
    {
      group              = aws_identitystore_group.notify_staging_admin_support_center,
      permission_set_arn = aws_ssoadmin_permission_set.admin_support_center.arn,
    },
    {
      group              = aws_identitystore_group.notify_staging_billing,
      permission_set_arn = data.aws_ssoadmin_permission_set.billing.arn,
    },
    {
      group              = aws_identitystore_group.notify_staging_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
    }
  ]
  # Notification-Dev
  notify_dev_permission_set_arns = [
    {
      group              = aws_identitystore_group.notify_dev_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
    },
    {
      group              = aws_identitystore_group.notify_dev_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
    },
  ]
  # Notification-Sandbox
  notify_sandbox_permission_set_arns = [
    {
      group              = aws_identitystore_group.notify_sandbox_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
    },
    {
      group              = aws_identitystore_group.notify_sandbox_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "notify_production" {
  for_each = { for perm in local.notify_production_permission_set_arns : perm.group.display_name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.notify_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "notify_staging" {
  for_each = { for perm in local.notify_staging_permission_set_arns : perm.group.display_name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.notify_staging_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "notify_dev" {
  for_each = { for perm in local.notify_dev_permission_set_arns : perm.group.display_name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.notify_dev_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "notify_sandbox" {
  for_each = { for perm in local.notify_sandbox_permission_set_arns : perm.group.display_name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.notify_sandbox_account_id
  target_type = "AWS_ACCOUNT"
}