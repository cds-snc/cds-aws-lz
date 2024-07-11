#
# Accounts: assign permissions
#
locals {
  # alpha.canada.ca Website
  alpha_canada_website_production_permission_sets = [
    {
      group          = aws_identitystore_group.alpha_canada_website_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.alpha_canada_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
  ]
  # Canadian Digital Service
  canadian_digital_services_production_permission_sets = [
    {
      group          = aws_identitystore_group.canadian_digital_service_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
    {
      group          = aws_identitystore_group.canadian_digital_service_production_website_admin,
      permission_set = aws_ssoadmin_permission_set.canadian_digital_service_production_website_admin,
    },
    # ! Cross Account Permission Assignment - Notify Hosted Zone
    {
      group          = aws_identitystore_group.notify_production_hosted_zone_admin,
      permission_set = aws_ssoadmin_permission_set.admin_route53_notify_hosted_zone,
    }
  ]
  # CdsWebsite-Production
  cds_website_production_permission_sets = [
    {
      group          = aws_identitystore_group.cds_website_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.cds_website_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
  ]
  # Website CMS
  cds_website_cms_production_permission_sets = [
    {
      group          = aws_identitystore_group.cds_website_cms_production_admin,
      permission_set = data.aws_ssoadmin_permission_set.aws_administrator_access,
    },
    {
      group          = aws_identitystore_group.cds_website_cms_production_read_only,
      permission_set = data.aws_ssoadmin_permission_set.aws_read_only_access,
    },
    {
      group          = aws_identitystore_group.cds_website_cms_production_read_only,
      permission_set = aws_ssoadmin_permission_set.read_only_billing,
    },
    {
      group          = aws_identitystore_group.cds_website_cms_production_support_center_admin,
      permission_set = aws_ssoadmin_permission_set.admin_support_center,
    },
  ]
}

resource "aws_ssoadmin_account_assignment" "alpha_canada_website_production" {
  for_each = { for perm in local.alpha_canada_website_production_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.alpha_canada_website_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "canadian_digital_services_production" {
  for_each = { for perm in local.canadian_digital_services_production_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.canadian_digital_services_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "cds_website_production" {
  for_each = { for perm in local.cds_website_production_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.cds_website_production_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "cds_website_cms_production" {
  for_each = { for perm in local.cds_website_cms_production_permission_sets : "${perm.group.display_name}-${perm.permission_set.name}" => perm }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = local.cds_website_cms_production_account_id
  target_type = "AWS_ACCOUNT"
}