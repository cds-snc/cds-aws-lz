#
# Accounts: assign permissions
#
locals {
  # Forms-Production
  forms_production_permission_sets = [
    {
      group          = aws_identitystore_group.forms_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.forms_production_athena_query_access,
      permission_set = aws_ssoadmin_permission_set.athena_query_access,
    },
    {
      group          = aws_identitystore_group.forms_production_rds_query_access,
      permission_set = aws_ssoadmin_permission_set.rds_query_access,
    },
    {
      group          = aws_identitystore_group.forms_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
    {
      group          = aws_identitystore_group.forms_production_read_only,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
  ]
  # Forms-Staging
  forms_staging_permission_sets = [
    {
      group          = aws_identitystore_group.forms_staging_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.forms_staging_athena_query_access,
      permission_set = aws_ssoadmin_permission_set.athena_query_access,
    },
    {
      group          = aws_identitystore_group.forms_staging_rds_query_access,
      permission_set = aws_ssoadmin_permission_set.rds_query_access,
    },
    {
      group          = aws_identitystore_group.forms_staging_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
    {
      group          = aws_identitystore_group.forms_staging_read_only,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "forms_production" {
  for_each = { for perm in local.forms_production_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.forms_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "forms_staging" {
  for_each = { for perm in local.forms_staging_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.forms_staging_account_id
  target_type = "AWS_ACCOUNT"
}
