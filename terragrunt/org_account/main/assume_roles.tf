
module "audit_plan" {
  source                 = "../../modules/allow_assumed_role"
  account_id             = "886481071419"
  name_of_role_to_assume = "assume_plan"
  assume_role_name       = local.plan_name
  billing_tag_value      = var.billing_code
}

module "audit_apply" {
  source                 = "../../modules/allow_assumed_role"
  account_id             = "886481071419"
  name_of_role_to_assume = "assume_apply"
  assume_role_name       = local.admin_name
  billing_tag_value      = var.billing_code
}