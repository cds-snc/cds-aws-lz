locals { 
  cartographyOrgListNamesname = "cartographyOrgListIds" 
}

# Plan Assume Role
module "assume_plan_role" {
  source                = "../../modules/assume_role"
  role_name             = "assumeCartographyOrg"
  org_account           = 794722365809 ## Not org account it's the account the role that is assuming this role sits in
  org_account_role_name = local.cartographyOrgListNamesname ## Not the org account role name but the name of the role assuming this role
  assume_policy_name    = "AssumePlanRole"
  billing_tag_value     = var.billing_code
}

# An IAM policy document that allows you to query all the accounts in an org
data "aws_iam_policy_document" "org_account_list" {
  statement {
    sid = "ListAccountsInOrg"

    effect = "Allow"

    actions = [
      "organizations:ListAccounts",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "org_account_list" {
  name   = "ListAccountsInOrg"
  policy = data.aws_iam_policy_document.org_account_list.json
}

# Attach the policy document to the role loca.org_account_list_name
resource "aws_iam_role_policy_attachment" "attach_list_accounts" {
  role       = local.org_account_list_name
  policy_arn = aws_iam_policy.org_account_list.arn
}