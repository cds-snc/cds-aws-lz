data "aws_caller_identity" "current" {}

locals {
  plan_name  = "cds-aws-lz-plan"
  apply_name = "cds-aws-lz-apply"
}

# Plan Assume Role
module "assume_plan_role" {
  source                = "../../modules/assume_role"
  role_name             = "assume_plan"
  org_account           = var.org_account
  org_account_role_name = local.plan_name
  assume_policy_name    = "AssumePlanRole"
  billing_tag_value     = var.billing_code

}

module "attach_tf_plan_policy_assume" {
  source            = "github.com/cds-snc/terraform-modules//attach_tf_plan_policy?ref=v3.0.20"
  account_id        = data.aws_caller_identity.current.account_id
  role_name         = "assume_plan"
  bucket_name       = "${var.billing_code}-tf"
  lock_table_name   = "terraform-state-lock-dynamo"
  billing_tag_value = var.billing_code
  policy_name       = "AssumePlan"
}

# Apply Assume Role

module "assume_apply_role" {
  source                = "../../modules/assume_role"
  role_name             = "assume_apply"
  org_account           = var.org_account
  org_account_role_name = local.apply_name
  assume_policy_name    = "AssumeApplyRole"
  billing_tag_value     = var.billing_code
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "assume_admin" {
  role       = module.assume_apply_role.role_name
  policy_arn = data.aws_iam_policy.admin.arn
}