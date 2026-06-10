locals {
  common_tags = {
    CostCentre = var.billing_code
    Terraform  = "true"
  }
  report_bucket_name = "${var.billing_code}-cost-report"
  report_prefix      = "cost-reports"
}
