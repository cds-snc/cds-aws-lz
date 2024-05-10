#
# Production
#
resource "aws_identitystore_group" "notify_production_access_ecs_blazer" {
  display_name      = "Notify-Production-ECS-Blazer-Access"
  description       = "Grants members access to the Notify Production account's ECS Blazer task."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_access_quicksight" {
  display_name      = "Notify-Production-QuickSight-Access"
  description       = "Grants members access to the Notify Production account's QuickSight service."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_access_vpc_clientvpn" {
  display_name      = "Notify-Production-VPC-ClientVPN-Access"
  description       = "Grants members access to the Notify Production Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_admin" {
  display_name      = "Notify-Production-Admin"
  description       = "Grants members administrator access to the Notify Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_admin_pinpoint_sms" {
  display_name      = "Notify-Production-Pinpoint-SMS-Admin"
  description       = "Grants members administrator access to the Notify Production account's Pinpoint SMS service."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_admin_s3_website_assets" {
  display_name      = "Notify-Production-S3-WebsiteAssets-Admin"
  description       = "Grants members administrator access to the Notify Production account's S3 website asset upload buckets."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_admin_support_center" {
  display_name      = "Notify-Production-SupportCenter-Admin"
  description       = "Grants members administrator access to the Notify Production account's Support Center."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_read_only_billing" {
  display_name      = "Notify-Production-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Notify Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_read_only" {
  display_name      = "Notify-Production-ReadOnly"
  description       = "Grants members read-only access to the Notify Production account."
  identity_store_id = local.sso_identity_store_id
}

#
# Staging
#
resource "aws_identitystore_group" "notify_staging_access_ecs_blazer" {
  display_name      = "Notify-Staging-ECS-Blazer-Access"
  description       = "Grants members access to the Notify Staging account's ECS Blazer task."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_access_vpc_clientvpn" {
  display_name      = "Notify-Staging-VPC-ClientVPN-Access"
  description       = "Grants members access to the Notify Staging Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_admin" {
  display_name      = "Notify-Staging-Admin"
  description       = "Grants members administrator access to the Notify Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_admin_pinpoint_sms" {
  display_name      = "Notify-Staging-Pinpoint-SMS-Admin"
  description       = "Grants members administrator access to the Notify Staging account's Pinpoint service."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_admin_s3_website_assets" {
  display_name      = "Notify-Staging-S3-WebsiteAssets-Admin"
  description       = "Grants members administrator access to the Notify Staging account's S3 website asset upload buckets."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_admin_support_center" {
  display_name      = "Notify-Staging-SupportCenter-Admin"
  description       = "Grants members administrator access to the Notify Staging account's Support Center."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_read_only_billing" {
  display_name      = "Notify-Staging-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the Notify Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_read_only" {
  display_name      = "Notify-Staging-ReadOnly"
  description       = "Grants members read-only access to the Notify Staging account."
  identity_store_id = local.sso_identity_store_id
}

#
# Dev
#
resource "aws_identitystore_group" "notify_dev_access_vpc_clientvpn" {
  display_name      = "Notify-Dev-VPC-ClientVPN-Access"
  description       = "Grants members access to the Notify Dev Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_dev_admin" {
  display_name      = "Notify-Dev-Admin"
  description       = "Grants members administrator access to the Notify Dev account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_dev_read_only" {
  display_name      = "Notify-Dev-ReadOnly"
  description       = "Grants members read-only access to the Notify Dev account."
  identity_store_id = local.sso_identity_store_id
}

#
# Sandbox
#
resource "aws_identitystore_group" "notify_sandbox_admin" {
  display_name      = "Notify-Sandbox-Admin"
  description       = "Grants members administrator access to the Notify Sandbox account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_sandbox_read_only" {
  display_name      = "Notify-Sandbox-ReadOnly"
  description       = "Grants members read-only access to the Notify Sandbox account."
  identity_store_id = local.sso_identity_store_id
}
