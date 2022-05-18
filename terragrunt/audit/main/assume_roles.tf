 
# Plan Assume Role
module "assume_plan_role" {
  source                = "../../modules/assume_role"
  role_name             = "assume_plan"
  org_account           = var.org_account
  org_account_role_name = local.plan_name
  assume_policy_name    = "AssumePlanRole"
  billing_tag_value     = var.billing_code

}

resource "aws_iam_role_policy_attachment" "assume_admin" {
  role       = module.assume_apply_role.role_name
  policy_arn = data.aws_iam_policy.admin.arn
}

# Apply Assume Role

module "assume_apply_role" {
  source                = "../../modules/assume_role"
  role_name             = "assume_apply"
  org_account           = var.org_account
  org_account_role_name = local.admin_name
  assume_policy_name    = "AssumeApplyRole"
  billing_tag_value     = var.billing_code
}

module "attach_tf_plan_policy_assume" {
  source            = "github.com/cds-snc/terraform-modules?ref=v2.0.2//attach_tf_plan_policy"
  account_id        = data.aws_caller_identity.current.account_id
  role_name         = local.plan_name
  bucket_name       = "${var.billing_code}-tf"
  lock_table_name   = "terraform-state-lock-dynamo"
  billing_tag_value = var.billing_code
  policy_name       = "AssumePlan"
  depends_on = [
    module.gh_oidc_roles
  ]
}