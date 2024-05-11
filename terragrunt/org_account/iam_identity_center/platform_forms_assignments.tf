#
# Accounts: assign permissions
#
locals {
  # Forms-Production
  forms_production_permission_set_arns = [
    {
      group              = aws_identitystore_group.forms_production_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
    },
    {
      group              = aws_identitystore_group.forms_production_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
    },
  ]
  # Forms-Staging
  forms_staging_permission_set_arns = [
    {
      group              = aws_identitystore_group.forms_staging_admin,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
    },
    {
      group              = aws_identitystore_group.forms_staging_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
    },
    {
      group              = aws_identitystore_group.forms_staging_read_only,
      permission_set_arn = data.aws_ssoadmin_permission_set.read_only_billing.arn,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "forms_production" {
  for_each = { for perm in local.forms_production_permission_set_arns : perm.group.display_name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.forms_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "forms_staging" {
  for_each = { for perm in local.forms_staging_permission_set_arns : perm.group.display_name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.forms_staging_account_id
  target_type = "AWS_ACCOUNT"
}
