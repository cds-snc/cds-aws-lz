module "forwarder" {
  source            = "github.com/cds-snc/terraform-modules?ref=v2.0.3//sentinel_forwarder"
  function_name     = "sentinel-guard-duty-forwarder"
  billing_tag_value = var.billing_code

  customer_id = var.customer_id
  shared_key  = var.shared_key

  s3_sources = [{
    bucket_arn    = module.guard_duty.s3_bucket_arn
    bucket_id     = module.guard_duty.s3_bucket_id
    filter_prefix = "AWSLogs/"
    kms_key_arn   = aws_kms_key.cds_sentinel_guard_duty_key.arn
  }]
}