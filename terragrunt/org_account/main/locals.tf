locals {
  plan_name                  = "CDSLZTerraformReadOnlyRole"
  admin_name                 = "CDSLZTerraformAdministratorRole"
  admin_plan_role            = "CDSLZTerraformAdminPlanRole"
  admin_account              = "274536870005"
  sre_sso_manage_permissions = "SSOManagePermissionsRole"
  sre_cloud_spend            = "CDSLZTerraformCloudSpendRole"

  sso_identity_store_id = "d-9d67173bdd"
  sso_instance_id       = "ssoins-8824c710b5ddb452"
}
