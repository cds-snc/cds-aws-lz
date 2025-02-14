locals {

  alpha_canada_website_production_account_id      = "414662622316"
  canadian_digital_services_production_account_id = "866996500832"
  cds_website_production_account_id               = "521732289257"
  cds_website_cms_production_account_id           = "773858180673"

  articles_production_account_id     = "472286471787"
  articles_staging_account_id        = "729164266357"
  list_manager_production_account_id = "762579868088"

  data_lake_production_account_id = "739275439843"

  design_system_production_account_id = "307395567143"

  digital_credentials_dev_account_id = "767397971970"

  gc_signin_dev_account_id        = "329599618423"
  gc_signin_production_account_id = "699475931199"
  gc_signin_staging_account_id    = "565393049229"

  digital_transformation_office_production_account_id = "730335533085"
  digital_transformation_office_staging_account_id    = "992382783569"

  forms_production_account_id = "957818836222"
  forms_staging_account_id    = "687401027353"

  notify_production_account_id = "296255494825"
  notify_staging_account_id    = "239043911459"
  notify_dev_account_id        = "800095993820"
  notify_sandbox_account_id    = "891376947407"

  superset_production_account_id = "066023111852"
  superset_staging_account_id    = "257394494478"

  sso_identity_store_id = "d-9d67173bdd"
  sso_instance_id       = "ssoins-8824c710b5ddb452"
  sso_instance_arn      = "arn:aws:sso:::instance/${local.sso_instance_id}"
}