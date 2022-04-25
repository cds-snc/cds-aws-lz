terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4"
    }
  }
}

provider "aws" {
  region              = "ca-central-1"
  allowed_account_ids = ["274536870005"]
}
