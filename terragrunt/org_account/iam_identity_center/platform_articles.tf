#
# Groups
#
resource "aws_identitystore_group" "articles_devs" {
  display_name      = "GCArticlesDevs"
  description       = "Grants members access to the GC Articles accounts."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "articles_vpn" {
  display_name      = "GCArticlesVPN"
  description       = "Grants members access to the GC Articles VPN."
  identity_store_id = local.sso_identity_store_id
}

#
# Accounts: assign groups and permission sets
#
locals {
  articles_permission_set_arns = [
    {
      name = "AWSAdministratorAccess",
      arn  = data.aws_ssoadmin_permission_set.aws_administrator_access.arn,
    },
    {
      name = "AWSReadOnlyAccess",
      arn  = data.aws_ssoadmin_permission_set.aws_read_only_access.arn,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "articles_devs_staging" {
  for_each = { for perm in local.articles_permission_set_arns : perm.name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.arn

  principal_id   = aws_identitystore_group.articles_devs.group_id
  principal_type = "GROUP"

  target_id   = "729164266357"
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "articles_devs_production" {
  for_each = { for perm in local.articles_permission_set_arns : perm.name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.arn

  principal_id   = aws_identitystore_group.articles_devs.group_id
  principal_type = "GROUP"

  target_id   = "472286471787"
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "articles_devs_platform_list_manager" {
  for_each = { for perm in local.articles_permission_set_arns : perm.name => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.arn

  principal_id   = aws_identitystore_group.articles_devs.group_id
  principal_type = "GROUP"

  target_id   = "762579868088"
  target_type = "AWS_ACCOUNT"
}

#
# Terraform state imports: remove after merge to `main`
#
import {
  to = aws_identitystore_group.articles_devs
  id = "${local.sso_identity_store_id}/2c2df578-9041-7052-74b1-a2d362f212bb"
}

import {
  to = aws_identitystore_group.articles_vpn
  id = "${local.sso_identity_store_id}/dccd4518-30d1-7014-0e65-d503dc3c4b75"
}

import {
  to = aws_ssoadmin_account_assignment.articles_devs_staging["AWSAdministratorAccess"]
  id = "${local.sso_identity_store_id}/2c2df578-9041-7052-74b1-a2d362f212bb,GROUP,729164266357,AWS_ACCOUNT,${data.aws_ssoadmin_permission_set.aws_administrator_access},${local.sso_instance_arn}"
}

import {
  to = aws_ssoadmin_account_assignment.articles_devs_staging["AWSReadOnlyAccess"]
  id = "${local.sso_identity_store_id}/2c2df578-9041-7052-74b1-a2d362f212bb,GROUP,729164266357,AWS_ACCOUNT,${data.aws_ssoadmin_permission_set.aws_read_only_access},${local.sso_instance_arn}"
}

import {
  to = aws_ssoadmin_account_assignment.articles_devs_production["AWSAdministratorAccess"]
  id = "${local.sso_identity_store_id}/2c2df578-9041-7052-74b1-a2d362f212bb,GROUP,472286471787,AWS_ACCOUNT,${data.aws_ssoadmin_permission_set.aws_administrator_access},${local.sso_instance_arn}"
}

import {
  to = aws_ssoadmin_account_assignment.articles_devs_production["AWSReadOnlyAccess"]
  id = "${local.sso_identity_store_id}/2c2df578-9041-7052-74b1-a2d362f212bb,GROUP,472286471787,AWS_ACCOUNT,${data.aws_ssoadmin_permission_set.aws_read_only_access},${local.sso_instance_arn}"
}

import {
  to = aws_ssoadmin_account_assignment.articles_devs_platform_list_manager["AWSAdministratorAccess"]
  id = "${local.sso_identity_store_id}/2c2df578-9041-7052-74b1-a2d362f212bb,GROUP,762579868088,AWS_ACCOUNT,${data.aws_ssoadmin_permission_set.aws_administrator_access},${local.sso_instance_arn}"
}

import {
  to = aws_ssoadmin_account_assignment.articles_devs_platform_list_manager["AWSReadOnlyAccess"]
  id = "${local.sso_identity_store_id}/2c2df578-9041-7052-74b1-a2d362f212bb,GROUP,762579868088,AWS_ACCOUNT,${data.aws_ssoadmin_permission_set.aws_read_only_access},${local.sso_instance_arn}"
}
