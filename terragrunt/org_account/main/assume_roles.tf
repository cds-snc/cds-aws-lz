# audit
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

# log archive
module "log_archive_plan" {
  source                 = "../../modules/allow_assumed_role"
  account_id             = "274536870005"
  name_of_role_to_assume = "assume_plan"
  assume_role_name       = local.plan_name
  billing_tag_value      = var.billing_code
}

module "log_archive_apply" {
  source                 = "../../modules/allow_assumed_role"
  account_id             = "274536870005"
  name_of_role_to_assume = "assume_apply"
  assume_role_name       = local.admin_name
  billing_tag_value      = var.billing_code
}

# AFT Management

module "AFT_management_plan" {
  source                 = "../../modules/allow_assumed_role"
  account_id             = "137554749751"
  name_of_role_to_assume = "assume_plan"
  assume_role_name       = local.plan_name
  billing_tag_value      = var.billing_code
}

module "AFT_management_apply" {
  source                 = "../../modules/allow_assumed_role"
  account_id             = "137554749751"
  name_of_role_to_assume = "assume_apply"
  assume_role_name       = local.admin_name
  billing_tag_value      = var.billing_code
}


