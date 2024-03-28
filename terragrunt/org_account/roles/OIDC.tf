
module "OIDC_Roles" {
  source      = "github.com/cds-snc/terraform-modules//gh_oidc_role?ref=v5.0.0"
  oidc_exists = true

  roles = [{
    name      = local.org_account_list_name
    repo_name = "site-reliability-engineering"
    claim     = "ref:refs/heads/main"
    },
    {
      name      = local.org_allow_policy_toggle
      repo_name = "site-reliability-engineering"
      claim     = "ref:refs/heads/main"
    },
    {
      name      = local.sre_identity_audit_oidc_role
      repo_name = "site-reliability-engineering"
      claim     = "ref:refs/heads/main"
    },
  ]

  billing_tag_value = var.billing_code
}

# An IAM policy document that allows you to query all the accounts in an OU
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

resource "aws_iam_policy" "org_account_list_in_sandbox" {
  name   = local.org_account_list_name
  policy = data.aws_iam_policy_document.org_account_list_in_sandbox.json

  tags = local.common_tags
}

# Attach the policy document to the role loca.org_account_list_name
resource "aws_iam_role_policy_attachment" "attach_list_accounts_in_sandbox" {
  role       = local.org_account_list_name
  policy_arn = aws_iam_policy.org_account_list_in_sandbox.arn
}

# temporary role to run toggle on/off the config recorder to run the aft vault backup cleanup script in a workflow
data "aws_iam_policy_document" "org_allow_policy_toggle" {
  statement {
    sid = "AllowPolicyToggle"

    actions = [
      "organizations:ListPoliciesForTarget",
      "organizations:ListRoots",
      "organizations:ListOrganizationalUnitsForParent",
      "organizations:DescribePolicy",
      "organizations:DetachPolicy",
      "organizations:AttachPolicy"
    ]

    resources = ["*"]
  }

}

resource "aws_iam_policy" "org_allow_policy_toggle" {
  name   = local.org_allow_policy_toggle
  policy = data.aws_iam_policy_document.org_allow_policy_toggle.json

  tags = local.common_tags

}

resource "aws_iam_role_policy_attachment" "attach_org_allow_policy_toggle" {
  role       = local.org_allow_policy_toggle
  policy_arn = aws_iam_policy.org_allow_policy_toggle.arn
  depends_on = [
    module.OIDC_Roles
  ]

}

data "aws_iam_policy_document" "assume_sre_identity_audit" {
  statement {
    sid = "AssumeSREIdentityAuditRoles"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      aws_iam_role.sre_identity_audit.arn,
      "arn:aws:iam::659087519042:role/sre_identity_audit" # org_account
    ]
  }
}

resource "aws_iam_policy" "assume_sre_identity_audit" {
  name   = local.sre_identity_audit_oidc_role
  policy = data.aws_iam_policy_document.assume_sre_identity_audit.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "assume_sre_identity_audit" {
  role       = local.sre_identity_audit_oidc_role
  policy_arn = aws_iam_policy.assume_sre_identity_audit.arn
}