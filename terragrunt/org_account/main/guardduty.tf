locals {
  admin_account = "274536870005"
}


resource "aws_guardduty_organization_admin_account" "gd_admin_ca_central_1" {
  depends_on       = [aws_organizations_organization.org_config]
  admin_account_id = local.admin_account
}

resource "aws_guardduty_organization_admin_account" "gd_admin_us_east_1" {
  provider         = aws.us-east-1
  depends_on       = [aws_organizations_organization.org_config]
  admin_account_id = local.admin_account
}

resource "aws_guardduty_organization_admin_account" "gd_admin_us_west_2" {
  provider         = aws.us-west-2
  depends_on       = [aws_organizations_organization.org_config]
  admin_account_id = local.admin_account
}
