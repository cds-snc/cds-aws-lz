locals {
  role_name = var.assume_role_name
}

provider "aws" {
  alias  = "audit_log"
  region = "ca-central-1"
  assume_role {
    role_arn = "arn:aws:iam::886481071419:role/${local.role_name}"
  }
}

module "test_bucket" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.4//S3"

  providers = {
    aws = aws.audit_log
  }

  versioning = {
    enabled = true
  }

  lifecycle_rule = [{
    enabled = true
    expiration = {
      days = 14
    }
  }]


  billing_tag_value = var.billing_code
}

