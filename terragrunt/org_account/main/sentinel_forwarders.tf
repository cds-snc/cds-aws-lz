# Guardduty
module "guardduty_forwarder" {
  providers = {
    aws = aws.log_archive
  }

  source            = "github.com/cds-snc/terraform-modules//sentinel_forwarder?ref=v3.0.19"
  function_name     = "sentinel-guard-duty-forwarder"
  billing_tag_value = var.billing_code

  customer_id = var.lw_customer_id
  shared_key  = var.lw_shared_key

  s3_sources = [
    {
      bucket_arn    = module.publishing_bucket.s3_bucket_arn
      bucket_id     = module.publishing_bucket.s3_bucket_id
      filter_prefix = "AWSLogs/"
      kms_key_arn   = aws_kms_key.cds_sentinel_guard_duty_key.arn
    }
  ]
}



# Security Hub

module "securityhub_forwarder" {
  providers = {
    aws = aws.log_archive
  }

  source            = "github.com/cds-snc/terraform-modules//sentinel_forwarder?ref=v3.0.19"
  function_name     = "sentinel-securityhub-forwarder"
  billing_tag_value = var.billing_code

  customer_id = var.lw_customer_id
  shared_key  = var.lw_shared_key

  event_rule_names = [aws_cloudwatch_event_rule.cds_sentinel_securityhub_rule.name]

}
