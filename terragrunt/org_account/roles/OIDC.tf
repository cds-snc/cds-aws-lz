
module "OIDC_Roles" {
  source      = "github.com/cds-snc/terraform-modules//gh_oidc_role?ref=v5.1.11"
  oidc_exists = true

  roles = [{
    name      = local.org_account_list_name
    repo_name = "site-reliability-engineering"
    claim     = "ref:refs/heads/main"
    },
    {
      name      = local.sre_identity_audit_oidc_role
      repo_name = "site-reliability-engineering"
      claim     = "ref:refs/heads/main"
    },
    {
      name      = local.org_account_list_all_name
      repo_name = "site-reliability-engineering"
      claim     = "ref:refs/heads/main"
    },
  ]

  billing_tag_value = var.billing_code
}

# An IAM policy document that allows you to query all the accounts in the sandbox OU
data "aws_iam_policy_document" "org_account_list_in_sandbox" {
  statement {
    sid = "ListAccountsInSandboxOU"

    actions = [
      "organizations:ListAccountsForParent",
    ]

    resources = [
      "arn:aws:organizations::659087519042:ou/o-625no8z3dd/ou-5gsq-9tmkqm3f",
    ]
  }
}

# An IAM policy document that allows you to query all the accounts in the org
data "aws_iam_policy_document" "org_account_list_all" {
  statement {
    sid = "listAllAccounts"

    actions = [
      "organizations:ListAccounts",
    ]

    resources = [
      "arn:aws:organizations::659087519042:ou/o-625no8z3dd/*",
    ]
  }
}

resource "aws_iam_policy" "org_account_list_in_sandbox" {
  name   = local.org_account_list_name
  policy = data.aws_iam_policy_document.org_account_list_in_sandbox.json
}

resource "aws_iam_policy" "org_account_list_all" {
  name   = local.org_account_list_all_name
  policy = data.aws_iam_policy_document.org_account_list_all.json
}

# Attach the policy document to the role local.org_account_list_name
resource "aws_iam_role_policy_attachment" "attach_list_accounts_in_sandbox" {
  role       = local.org_account_list_name
  policy_arn = aws_iam_policy.org_account_list_in_sandbox.arn
}

# Attach the policy document to the role local.org_account_list_all_name
resource "aws_iam_role_policy_attachment" "attach_list_accounts_all" {
  role       = local.org_account_list_all_name
  policy_arn = aws_iam_policy.org_account_list_all.arn
}
