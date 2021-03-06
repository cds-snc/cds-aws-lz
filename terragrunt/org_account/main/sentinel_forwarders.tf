# Cloudtrail
module "cloudtrail_forwarder" {
  providers = {
    aws = aws.log_archive
  }

  source            = "github.com/cds-snc/terraform-modules?ref=v3.0.2//sentinel_forwarder"
  function_name     = "sentinel-cloud-trail-forwarder"
  billing_tag_value = var.billing_code

  customer_id = var.lw_customer_id
  shared_key  = var.lw_shared_key

  s3_sources = [
    {
      bucket_arn    = "arn:aws:s3:::aws-aft-logs-${data.aws_caller_identity.log_archive.account_id}-${var.region}"
      bucket_id     = "aws-aft-logs-${data.aws_caller_identity.log_archive.account_id}-${var.region}"
      filter_prefix = "AWSLogs/o-625no8z3dd/"
      kms_key_arn   = "arn:aws:kms:${var.region}:${data.aws_caller_identity.log_archive.account_id}:key/72713e0c-b7f4-438a-9eca-41c36b775f30"
    }
  ]
}



# Guardduty
module "guardduty_forwarder" {
  providers = {
    aws = aws.log_archive
  }

  source            = "github.com/cds-snc/terraform-modules?ref=v3.0.2//sentinel_forwarder"
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

  source            = "github.com/cds-snc/terraform-modules?ref=v3.0.2//sentinel_forwarder"
  function_name     = "sentinel-securityhub-forwarder"
  billing_tag_value = var.billing_code

  customer_id = var.lw_customer_id
  shared_key  = var.lw_shared_key

  event_rule_names = [aws_cloudwatch_event_rule.cds_sentinel_securityhub_rule.name]

}