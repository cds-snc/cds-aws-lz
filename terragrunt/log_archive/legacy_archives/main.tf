module "aws-landing-zone-logs_bucket" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.19//S3"
  bucket_name = "legacy-aws-landing-zone-logs_bucket"
  billing_tag_value = var.billing_code
}

module "aws-landing-zone-s3-access-logs_bucket" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.19//S3"
  bucket_name = "legacy-aws-landing-zone-s3-access-logs_bucket"
  billing_tag_value = var.billing_code
}