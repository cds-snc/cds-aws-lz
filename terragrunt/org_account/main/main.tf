module "password_policy" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.2//aws_goc_password_policy"
}



# Grant access to the AFT Management account to AFT Product in the Service Catalog:
# https://learn.hashicorp.com/tutorials/terraform/aws-control-tower-aft#grant-aft-access-to-service-catalog-portfolio
data "aws_servicecatalog_portfolio" "account_factory" {
  id = "port-dpatq4en6lqoy"
}

data "aws_iam_role" "aft_execution_role" {
  name = "AWSAFTExecution"
}

resource "aws_servicecatalog_principal_portfolio_association" "aft_role_account_factory" {
  portfolio_id  = data.aws_servicecatalog_portfolio.account_factory.id
  principal_arn = data.aws_iam_role.aft_execution_role.arn
}

resource "aws_organizations_organization" "org_config" {

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",   # Enabled by Control Tower
    "config.amazonaws.com",       # Enabled by Control Tower
    "sso.amazonaws.com",          # Enabled by Control Tower
    "controltower.amazonaws.com", # Enabled by Control Tower
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "reporting.trustedadvisor.amazonaws.com"
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]

  feature_set = "ALL"
}

locals {
  root = aws_organizations_organization.org_config.roots[0].id
}

resource "aws_organizations_organizational_unit" "AFT" {
  name      = "AFT"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "DumpsterFire" {
  name      = "DumpsterFire"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "Production" {
  name      = "Production"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "Sandbox" {
  name      = "Sandbox"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "Security" {
  name      = "Security"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "SRETools" {
  name      = "SRETools"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "Staging" {
  name      = "Staging"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "Test" {
  name      = "Test"
  parent_id = local.root
}