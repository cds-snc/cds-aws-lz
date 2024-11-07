locals {
  common_tags = {
    CostCentre = var.billing_code
    Terraform  = "true"
  }
  data_lake_raw_s3_bucket_arn = "arn:aws:s3:::cds-data-lake-raw-production"
}