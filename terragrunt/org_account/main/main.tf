module "password_policy" {
  source = "../modules/password_policy"
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
    "cloudtrail.amazonaws.com", # Enabled by Control Tower
    "config.amazonaws.com", # Enabled by Control Tower
    "sso.amazonaws.com", # Enabled by Control Tower
    "controltower.amazonaws.com", # Enabled by Control Tower
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com"
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]

  feature_set = "ALL"
}