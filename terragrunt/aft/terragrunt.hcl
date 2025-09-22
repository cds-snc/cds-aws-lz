
locals {
  account_id       = "137554749751"
  env              = "production"
  product_name     = "cds-aft-management"
  cost_center_code = "${local.product_name}-${local.env}"
}

# DO NOT CHANGE ANYTHING BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING

inputs = {
  account_id                    = local.account_id
  env                           = local.env
  product_name                  = local.product_name
  region                        = "ca-central-1"
  billing_code                  = local.cost_center_code
  org_account                   = "659087519042"
  slack_notification_lambda_arn = module.aft_slack_notification.lambda_arn
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file("../common/provider.tf")

}

generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"
  contents  = file("../common/common_variables.tf")
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt             = true
    bucket              = "${local.cost_center_code}-tf"
    dynamodb_table      = "terraform-state-lock-dynamo"
    region              = "ca-central-1"
    key                 = "${path_relative_to_include()}/terraform.tfstate"
    s3_bucket_tags      = { CostCenter : local.cost_center_code }
    dynamodb_table_tags = { CostCenter : local.cost_center_code }
  }
}