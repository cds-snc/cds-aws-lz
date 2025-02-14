# Accounts: assign permissions
#
locals {
  # GCSignIn-Production
  gc_signin_production_permission_sets = [
    {
      group          = aws_identitystore_group.gc_signin_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.gc_signin_production_read_only_billing,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
    {
      group          = aws_identitystore_group.gc_signin_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    }
  ]
  # GCSignin-Staging
  gc_signin_staging_permission_sets = [
    {
      group          = aws_identitystore_group.gc_signin_staging_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.gc_signin_staging_read_only_billing,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
    {
      group          = aws_identitystore_group.gc_signin_staging_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    }
  ]
  # GCSignin-Dev
  gc_signin_dev_permission_sets = [
    {
      group          = aws_identitystore_group.gc_signin_dev_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.gc_signin_dev_read_only_billing,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
    {
      group          = aws_identitystore_group.gc_signin_dev_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    }
  ]
}

resource "aws_ssoadmin_account_assignment" "gc_signin_production" {
  for_each = { for perm in local.gc_signin_production_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.gc_signin_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "gc_signin_staging" {
  for_each = { for perm in local.gc_signin_staging_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.gc_signin_staging_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "gc_signin_dev" {
  for_each = { for perm in local.gc_signin_dev_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.gc_signin_dev_account_id
  target_type = "AWS_ACCOUNT"
}
