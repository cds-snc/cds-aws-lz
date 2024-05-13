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

moved {
  from = aws_ssoadmin_account_assignment.notify_dev["Notify-Dev-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_dev["Notify-Dev-Admin-AWSAdministratorAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_dev["Notify-Dev-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.notify_dev["Notify-Dev-ReadOnly-AWSReadOnlyAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_production["Notify-Production-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_production["Notify-Production-Admin-AWSAdministratorAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_production["Notify-Production-Billing-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.notify_production["Notify-Production-Billing-ReadOnly-Billing-ReadOnly"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_production["Notify-Production-ECS-Blazer-Access"]
  to   = aws_ssoadmin_account_assignment.notify_production["Notify-Production-ECS-Blazer-Access-ECS-Blazer-Access"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_production["Notify-Production-Pinpoint-SMS-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_production["Notify-Production-Pinpoint-SMS-Admin-Pinpoint-SMS-Admin"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_production["Notify-Production-QuickSight-Access"]
  to   = aws_ssoadmin_account_assignment.notify_production["Notify-Production-QuickSight-Access-Quicksight"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_production["Notify-Production-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.notify_production["Notify-Production-ReadOnly-AWSReadOnlyAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_production["Notify-Production-S3-WebsiteAssets-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_production["Notify-Production-S3-WebsiteAssets-Admin-S3-NotifyWebsiteAssets-Admin"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_production["Notify-Production-SupportCenter-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_production["Notify-Production-SupportCenter-Admin-SupportCenter-Admin"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_sandbox["Notify-Sandbox-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_sandbox["Notify-Sandbox-Admin-AWSAdministratorAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_sandbox["Notify-Sandbox-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.notify_sandbox["Notify-Sandbox-ReadOnly-AWSReadOnlyAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-Admin-AWSAdministratorAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-Billing-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-Billing-ReadOnly-Billing-ReadOnly"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-ECS-Blazer-Access"]
  to   = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-ECS-Blazer-Access-ECS-Blazer-Access"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-Pinpoint-SMS-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-Pinpoint-SMS-Admin-Pinpoint-SMS-Admin"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-ReadOnly"]
  to   = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-ReadOnly-AWSReadOnlyAccess"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-S3-WebsiteAssets-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-S3-WebsiteAssets-Admin-S3-NotifyWebsiteAssets-Admin"]
}

moved {
  from = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-SupportCenter-Admin"]
  to   = aws_ssoadmin_account_assignment.notify_staging["Notify-Staging-SupportCenter-Admin-SupportCenter-Admin"]
}