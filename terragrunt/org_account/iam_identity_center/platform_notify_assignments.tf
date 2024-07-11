#
# Accounts: assign permissions
#
locals {
  # Notification-Production
  notify_production_permission_sets = [
    {
      group          = aws_identitystore_group.notify_production_access_ecs_blazer,
      permission_set = aws_ssoadmin_permission_set.notify_access_ecs_blazer,
    },
    {
      group          = aws_identitystore_group.notify_production_access_quicksight,
      permission_set = aws_ssoadmin_permission_set.quicksight,
    },
    {
      group          = aws_identitystore_group.notify_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.notify_production_admin_pinpoint_sms,
      permission_set = aws_ssoadmin_permission_set.admin_pinpoint_sms,
    },
    {
      group          = aws_identitystore_group.notify_production_admin_s3_website_assets,
      permission_set = aws_ssoadmin_permission_set.admin_s3_website_assets,
    },
    {
      group          = aws_identitystore_group.notify_production_admin_support_center,
      permission_set = aws_ssoadmin_permission_set.admin_support_center,
    },
    {
      group          = aws_identitystore_group.notify_production_read_only_billing,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
    {
      group          = aws_identitystore_group.notify_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
    {
      group          = aws_identitystore_group.notify_production_hosted_zone_admin,
      permission_set = aws_ssoadmin_permission_set.admin_route53_notify_hosted_zone,
    }
  ]
  # Notification-Staging
  notify_staging_permission_sets = [
    {
      group          = aws_identitystore_group.notify_staging_access_ecs_blazer,
      permission_set = aws_ssoadmin_permission_set.notify_access_ecs_blazer,
    },
    {
      group          = aws_identitystore_group.notify_staging_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.notify_staging_admin_pinpoint_sms,
      permission_set = aws_ssoadmin_permission_set.admin_pinpoint_sms,
    },
    {
      group          = aws_identitystore_group.notify_staging_admin_s3_website_assets,
      permission_set = aws_ssoadmin_permission_set.admin_s3_website_assets,
    },
    {
      group          = aws_identitystore_group.notify_staging_admin_support_center,
      permission_set = aws_ssoadmin_permission_set.admin_support_center,
    },
    {
      group          = aws_identitystore_group.notify_staging_read_only_billing,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
    {
      group          = aws_identitystore_group.notify_staging_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    }
  ]
  # Notification-Dev
  notify_dev_permission_sets = [
    {
      group          = aws_identitystore_group.notify_dev_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.notify_dev_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
  ]
  # Notification-Sandbox
  notify_sandbox_permission_sets = [
    {
      group          = aws_identitystore_group.notify_sandbox_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.notify_sandbox_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "notify_production" {
  for_each = { for perm in local.notify_production_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.notify_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "notify_staging" {
  for_each = { for perm in local.notify_staging_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.notify_staging_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "notify_dev" {
  for_each = { for perm in local.notify_dev_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.notify_dev_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "notify_sandbox" {
  for_each = { for perm in local.notify_sandbox_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.notify_sandbox_account_id
  target_type = "AWS_ACCOUNT"
}
