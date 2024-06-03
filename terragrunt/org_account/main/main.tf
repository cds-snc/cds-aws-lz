module "password_policy" {
  source = "github.com/cds-snc/terraform-modules//aws_goc_password_policy?ref=v3.0.20"
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

