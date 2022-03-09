module "password_policy" {
  source = "github.com/cds-snc/terraform-modules?ref=v1.0.14//aws_goc_password_policy"
}


module "account_factory_for_terraform" {
  source = "github.com/aws-ia/terraform-aws-control_tower_account_factory?ref=1.3.3"

  terraform_version = "1.1.6"

  vcs_provider                                  = "github"
  account_customizations_repo_name              = "cds-snc/aft-account-customizations"
  account_provisioning_customizations_repo_name = "cds-snc/aft-account-provisioning-customizations"
  account_request_repo_name                     = "cds-snc/aft-account-request"
  global_customizations_repo_name               = "cds-snc/aft-global-customizations"

  ct_home_region              = var.region
  tf_backend_secondary_region = "us-east-1"

  aft_management_account_id = var.account_id
  audit_account_id          = "886481071419"
  ct_management_account_id  = "659087519042"
  log_archive_account_id    = "274536870005"

  aft_feature_cloudtrail_data_events      = true
  aft_feature_delete_default_vpcs_enabled = true
  aft_feature_enterprise_support          = false
  cloudwatch_log_group_retention          = 90

}