locals {
  common_tags = {
    CostCentre = var.billing_code
    Terraform  = "true"
    Critical   = "true"
  }
}
