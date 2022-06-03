
locals {
  role_name         = var.assume_role_name
  log_archive_id    = "274536870005"
  audit_id          = "886481071419"
  aft_management_id = "137554749751"
}

# Audit Providers

provider "aws" {
  alias  = "audit_log"
  region = "ca-central-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.audit_id}:role/${local.role_name}"
  }
}

provider "aws" {
  alias  = "audit_log_us_east_1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.audit_id}:role/${local.role_name}"
  }
}

provider "aws" {
  alias  = "audit_log_us_west_2"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${local.audit_id}:role/${local.role_name}"
  }
}

# Log Archive Providers
provider "aws" {
  alias  = "log_archive"
  region = "ca-central-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.log_archive_id}:role/${local.role_name}"
  }
}

provider "aws" {
  alias  = "log_archive_us_east_1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.log_archive_id}:role/${local.role_name}"
  }
}

provider "aws" {
  alias  = "log_archive_us_west_2"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${local.log_archive_id}:role/${local.role_name}"
  }
}


# AFT-Management Providers

provider "aws" {
  alias  = "aft_management"
  region = "ca-central-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.aft_management_id}:role/${local.role_name}"
  }
}

provider "aws" {
  alias  = "aft_management_us_east_1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.aft_management_id}:role/${local.role_name}"
  }
}

provider "aws" {
  alias  = "aft_management_us_west_2"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${local.aft_management_id}:role/${local.role_name}"
  }
}