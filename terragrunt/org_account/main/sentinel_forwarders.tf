# Guardduty
module "guardduty_forwarder" {
  providers = {
    aws = aws.log_archive
  }

  source            = "github.com/cds-snc/terraform-modules//sentinel_forwarder?ref=v11.4.7"
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

  source            = "github.com/cds-snc/terraform-modules//sentinel_forwarder?ref=v11.4.7"
  function_name     = "sentinel-securityhub-forwarder"
  billing_tag_value = var.billing_code

  layer_arn = "arn:aws:lambda:ca-central-1:283582579564:layer:aws-sentinel-connector-layer:266"

  customer_id = var.lw_customer_id
  shared_key  = var.lw_shared_key

  event_rule_names = [aws_cloudwatch_event_rule.cds_sentinel_securityhub_rule.name]

}
