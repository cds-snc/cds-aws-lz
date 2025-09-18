locals {
  account_ids = [for acct in data.aws_organizations_organization.org.accounts : acct.id]
}

resource "aws_ssoadmin_account_assignment" "internal_sre" {
  for_each = toset(local.account_ids)

  instance_arn       = local.sso_instance_arn
  permission_set_arn = data.aws_ssoadmin_permission_set.aws_administrator_access.arn

  principal_id   = aws_identitystore_group.awsops.group_id
  principal_type = "GROUP"

  target_id   = each.key
  target_type = "AWS_ACCOUNT"
}


resource "aws_ssoadmin_account_assignment" "internal_sre_read_only" {
  for_each = toset(local.account_ids)

  instance_arn       = local.sso_instance_arn
  permission_set_arn = data.aws_ssoadmin_permission_set.aws_read_only_access.arn

  principal_id   = aws_identitystore_group.awsops_read_only.group_id
  principal_type = "GROUP"

  target_id   = each.key
  target_type = "AWS_ACCOUNT"
}