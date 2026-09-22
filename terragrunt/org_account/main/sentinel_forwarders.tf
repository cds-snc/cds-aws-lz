locals {
  # Phase 2 — the Logs Ingestion API (DCE/DCR) half of the forwarder config.
  #
  # These are bootstrap constants, the same kind as the Cognito IdentityId: they
  # name Azure resources built in cds-snc/sentinel and cds-snc/cds-azure-resources,
  # which this account cannot read. Source of truth for the first three is the
  # `forwarder_v2_dce_endpoint` / `forwarder_v2_aws_dcr_config` outputs on
  # terraform-cds-snc-la.
  sentinel_v2_dce_endpoint = "https://dce-sentinel-forwarder-v2-153n.canadacentral-1.ingest.monitor.azure.com"

  # Keyed by the log type connector.py computes from the event, not by anything
  # configurable — an EventBridge Security Hub event dispatches as
  # "AWSSecurityHub". Only that key is given: this forwarder has no CloudWatch
  # subscription, and an entry it cannot reach would only obscure that.
  sentinel_v2_dcr_config = {
    AWSSecurityHub = {
      dcrImmutableId = "dcr-804905b66f7344d18dfe1606d489a599"
      streamName     = "Custom-AWSSecurityHub_v2_Input"
    }
  }

  # The user-assigned managed identity sentinel-forwarder-v2-aws-cognito, in the
  # CDS tenant. Not an app registration — see cds-azure-resources#98.
  sentinel_v2_azure_client_id = "9fd2a8dc-1698-4291-a71f-19ddc3cef71f"
  sentinel_v2_azure_tenant_id = "221ca1d3-b3f2-4346-8abc-88f802495c7d"
}

# Guardduty
#
# Stays on the Data Collector API. It has no trigger — cds-aws-lz#449 records it
# as dead code awaiting removal — so giving it a v2 credential would be new reach
# for nothing. It takes v12.0.0 anyway, as the v1 control: v11.4.7 and v12.0.0
# are byte-identical outside #923, so anything this one plans is C and only C.
module "guardduty_forwarder" {
  providers = {
    aws = aws.log_archive
  }

  source            = "github.com/cds-snc/terraform-modules//sentinel_forwarder?ref=v12.0.0"
  function_name     = "sentinel-guard-duty-forwarder"
  billing_tag_value = var.billing_code

  layer_arn = "arn:aws:lambda:ca-central-1:283582579564:layer:aws-sentinel-connector-layer:266"

  customer_id = var.lw_customer_id
  shared_key  = var.lw_shared_key
}



# Security Hub

module "securityhub_forwarder" {
  providers = {
    aws = aws.log_archive
  }

  source            = "github.com/cds-snc/terraform-modules//sentinel_forwarder?ref=v12.0.0"
  function_name     = "sentinel-securityhub-forwarder"
  billing_tag_value = var.billing_code

  # 270, not 266: every version up to 269 was built for CPython 3.12 while this
  # module runs the Lambda on python3.13, so the v2 Azure import raised
  # `No module named '_cffi_backend'` on every invocation. The wrapper catches
  # it and returns normally, so the Errors metric stayed at 0 while ~49,000
  # findings were dropped between 2026-09-17 and 2026-09-22.
  # Fixed in aws-sentinel-connector-layer#302.
  layer_arn = "arn:aws:lambda:ca-central-1:283582579564:layer:aws-sentinel-connector-layer:270"

  # Kept deliberately. The layer picks v2 whenever DCE_ENDPOINT and DCR_CONFIG
  # are both set and never reads these in that case, so leaving them in place
  # makes the rollback a config change rather than a state change. They come out
  # in workstream E, with the v1 code path.
  customer_id = var.lw_customer_id
  shared_key  = var.lw_shared_key

  # v2: no secret is stored at any point. The Lambda's IAM role mints a Cognito
  # OIDC token, which is presented to Entra as a client assertion for the managed
  # identity above, which holds Monitoring Metrics Publisher on the DCRs.
  dce_endpoint                    = local.sentinel_v2_dce_endpoint
  dcr_config                      = local.sentinel_v2_dcr_config
  azure_client_id                 = local.sentinel_v2_azure_client_id
  azure_tenant_id                 = local.sentinel_v2_azure_tenant_id
  cognito_identity_pool_id        = aws_cognito_identity_pool.sentinel_forwarder_v2.id
  cognito_developer_provider_name = local.sentinel_forwarder_cognito_developer_provider_name

  event_rule_names = [aws_cloudwatch_event_rule.cds_sentinel_securityhub_rule.name]

}
