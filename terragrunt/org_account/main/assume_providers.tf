
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

provider "aws" {
  alias  = "log_archive"
  region = "ca-central-1"
  assume_role {
    role_arn = "arn:aws:iam::274536870005:role/${local.role_name}"
  }
}

provider "aws" {
  alias  = "aft_management"
  region = "ca-central-1"
  assume_role {
    role_arn = "arn:aws:iam::137554749751:role/${local.role_name}"
  }
}