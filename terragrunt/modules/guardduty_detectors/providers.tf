terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.ca_central_1, aws.us_east_1, aws.us_west_2]
    }
  }
}