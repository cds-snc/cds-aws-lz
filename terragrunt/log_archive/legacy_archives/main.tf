module "aws-landing-zone-logs_bucket" {
  source = "github.com/cds-snc/terraform-modules//S3?ref=v3.0.20"

  bucket_name       = "legacy-aws-landing-zone-logs"
  billing_tag_value = var.billing_code

  kms_key_arn = "arn:aws:kms:ca-central-1:${var.account_id}:alias/aws/s3"
}

module "aws-landing-zone-s3-access-logs_bucket" {
  source = "github.com/cds-snc/terraform-modules//S3?ref=v3.0.20"

  bucket_name       = "legacy-aws-landing-zone-s3-access-logs"
  billing_tag_value = var.billing_code

  kms_key_arn = "arn:aws:kms:ca-central-1:${var.account_id}:alias/aws/s3"
}
