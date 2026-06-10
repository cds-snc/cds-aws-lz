module "cost_report_bucket" {
  source      = "github.com/cds-snc/terraform-modules//S3?ref=v9.6.8"
  bucket_name = local.report_bucket_name

  versioning = {
    enabled = true
  }

  billing_tag_value = var.billing_code
}
