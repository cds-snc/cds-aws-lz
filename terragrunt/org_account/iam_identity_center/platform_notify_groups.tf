#
# Production
#
resource "aws_identitystore_group" "notify_production_access_ecs_blazer" {
  display_name      = "Notify-Production-Access-ECS-Blazer"
  description       = "Grants members access to the Notify Production account's ECS Blazer task."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_access_quicksight" {
  display_name      = "Notify-Production-Access-QuickSight"
  description       = "Grants members access to the Notify Production account's QuickSight service."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_access_vpc_clientvpn" {
  display_name      = "Notify-Production-Access-VPC-ClientVPN"
  description       = "Grants members access to the Notify Production Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_admin" {
  display_name      = "Notify-Production-Admin"
  description       = "Grants members administrator access to the Notify Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_admin_pinpoint_sms" {
  display_name      = "Notify-Production-Admin-Pinpoint-SMS"
  description       = "Grants members administrator access to the Notify Production account's Pinpoint SMS service."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_admin_s3_website_assets" {
  display_name      = "Notify-Production-Admin-S3-WebsiteAssets"
  description       = "Grants members administrator access to the Notify Production account's S3 website asset upload buckets."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_admin_support_center" {
  display_name      = "Notify-Production-Admin-SupportCenter"
  description       = "Grants members administrator access to the Notify Production account's Support Center."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_production_billing" {
  display_name      = "Notify-Production-Billing"
  description       = "Grants members billing access to the Notify Production account."
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
  display_name      = "Notify-Staging-Access-ECS-Blazer"
  description       = "Grants members access to the Notify Staging account's ECS Blazer task."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_access_vpc_clientvpn" {
  display_name      = "Notify-Staging-Access-VPC-ClientVPN"
  description       = "Grants members access to the Notify Staging Client VPN."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_admin" {
  display_name      = "Notify-Staging-Admin"
  description       = "Grants members administrator access to the Notify Staging account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_admin_pinpoint_sms" {
  display_name      = "Notify-Staging-Admin-Pinpoint-SMS"
  description       = "Grants members administrator access to the Notify Staging account's Pinpoint service."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_admin_s3_website_assets" {
  display_name      = "Notify-Staging-Admin-S3-WebsiteAssets"
  description       = "Grants members administrator access to the Notify Staging account's S3 website asset upload buckets."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_admin_support_center" {
  display_name      = "Notify-Staging-Admin-SupportCenter"
  description       = "Grants members administrator access to the Notify Staging account's Support Center."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "notify_staging_billing" {
  display_name      = "Notify-Staging-Billing"
  description       = "Grants members billing access to the Notify Staging account."
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
  display_name      = "Notify-Dev-Access-VPC-ClientVPN"
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
