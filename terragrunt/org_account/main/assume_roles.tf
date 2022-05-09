module "audit_plan_role" {
  source              = "../modules/assume_role"
  assume_account_id   = "886481071419"
  role_name_to_assume = "CDSLZTerraformReadOnlyRole"
  billing_tag_value   = var.billing_code
}

module "audit_apply_role" {
  source              = "../modules/assume_role"
  assume_account_id   = "886481071419"
  role_name_to_assume = "CDSLZTerraformAdministratorRole"
  billing_tag_value   = var.billing_code
}