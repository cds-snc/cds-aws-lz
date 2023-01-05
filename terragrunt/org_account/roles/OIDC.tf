locals { 
  org_account_list_name = "listAccountsInOrg"
}

module "OIDC_Roles" {
  source      = "github.com/cds-snc/terraform-modules?ref=v5.0.0//gh_oidc_role"
  oidc_exists = true

  roles = [{
    name      = local.org_account_list_name
    repo_name = "site-reliability-engineering"
    claim     = "ref:refs/heads/main"
  }]
}


# An IAM policy document that allows you to query all the accounts in an OU
data "aws_iam_policy_document" "org_account_list_in_sandbox" {
  statement {
    sid = "ListAccountsInSandboxOU"

    actions = [
      "organizations:ListAccountsForParent",
    ]

    resources = [
      "arn:aws:organizations::659087519042:ou/o-625no8z3dd/ou-5gsq-qhvjdryl",
    ]
  }
}

resource "aws_iam_policy" "org_account_list_in_sandbox" {
  name               = local.org_account_list_name
  assume_role_policy = data.aws_iam_policy_document.org_account_list_in_sandbox.json
}

# Attach the policy document to the role loca.org_account_list_name
resource "aws_iam_role_policy_attachment" "attach_list_accounts_in_sandbox" {
  role       = local.org_account_list_name
  policy_arn = aws_iam_policy.org_account_list_in_sandbox.arn
}