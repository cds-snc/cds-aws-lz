

module "gh_oidc_roles" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.2//gh_oidc_role"
  roles = [
    {
      name      = local.plan_name
      repo_name = "cds-aws-lz"
      claim     = "*"
    },
    {
      name      = local.admin_name
      repo_name = "cds-aws-lz"
      claim     = "ref:refs/heads/main"
    },
    {
      name      = local.admin_plan_role
      repo_name = "cds-aws-lz"
      claim     = "*"
    }
  ]

  billing_tag_value = var.billing_code
}

module "attach_tf_plan_policy" {
  source            = "github.com/cds-snc/terraform-modules?ref=v3.0.2//attach_tf_plan_policy"
  account_id        = data.aws_caller_identity.current.account_id
  role_name         = local.plan_name
  bucket_name       = "${var.billing_code}-tf"
  lock_table_name   = "terraform-state-lock-dynamo"
  billing_tag_value = var.billing_code
  policy_name       = "CDSLZTFPlan"
  depends_on = [
    module.gh_oidc_roles
  ]
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
  depends_on = [
    module.gh_oidc_roles
  ]
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = local.admin_name
  policy_arn = data.aws_iam_policy.admin.arn
  depends_on = [
    module.gh_oidc_roles
  ]
}

resource "aws_iam_role_policy_attachment" "admin_plan" {
  role       = local.admin_plan_role
  policy_arn = data.aws_iam_policy.admin.arn
  depends_on = [
    module.gh_oidc_roles
  ]
}