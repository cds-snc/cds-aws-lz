locals {
  articles_production_account_id = "472286471787"
  articles_staging_account_id    = "729164266357"

  design_system_production_account_id = "307395567143"

  digital_credentials_dev_account_id = "767397971970"

  forms_production_account_id = "957818836222"
  forms_staging_account_id    = "687401027353"

  list_manager_production_account_id = "762579868088"

  notify_production_account_id = "296255494825"
  notify_staging_account_id    = "239043911459"
  notify_dev_account_id        = "800095993820"
  notify_sandbox_account_id    = "891376947407"

  sso_identity_store_id = "d-9d67173bdd"
  sso_instance_id       = "ssoins-8824c710b5ddb452"
  sso_instance_arn      = "arn:aws:sso:::instance/${local.sso_instance_id}"
}