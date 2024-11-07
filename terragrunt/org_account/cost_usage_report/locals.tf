locals {
  common_tags = {
    CostCentre = var.billing_code
    Terraform  = "true"
  }
  data_lake_raw_s3_bucket_arn  = "arn:aws:s3:::${local.data_lake_raw_s3_bucket_name}"
  data_lake_raw_s3_bucket_name = "cds-data-lake-raw-production"
}