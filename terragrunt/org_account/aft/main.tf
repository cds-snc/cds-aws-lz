module "account_factory_for_terraform" {
  source = "github.com/aws-ia/terraform-aws-control_tower_account_factory?ref=1.18.0"

  terraform_version = "1.7.2"

  vcs_provider                                  = "github"
  account_customizations_repo_name              = "cds-snc/aft-account-customizations"
  account_provisioning_customizations_repo_name = "cds-snc/aft-account-provisioning-customizations"
  account_request_repo_name                     = "cds-snc/aft-account-request"
  global_customizations_repo_name               = "cds-snc/aft-global-customizations"

  ct_home_region              = var.region
  tf_backend_secondary_region = "us-east-1"

  aft_management_account_id = "137554749751"
  audit_account_id          = "886481071419"
  ct_management_account_id  = var.account_id
  log_archive_account_id    = "274536870005"

  aft_feature_cloudtrail_data_events      = false
  aft_feature_delete_default_vpcs_enabled = true
  aft_feature_enterprise_support          = true
  cloudwatch_log_group_retention          = 90

}