# Aggregate AWS Config data from all accounts and regions in the organization
resource "aws_config_configuration_aggregator" "organization" {
  name = "cds-cbr-tags-aggregator"

  organization_aggregation_source {
    regions  = ["ca-central-1", "us-east-1"]
    role_arn = aws_iam_role.config_aggregator.arn
  }
}

# IAM role assumed by AWS Config to collect data across the organization
resource "aws_iam_role" "config_aggregator" {
  name = "AWSConfigRoleForOrganizations"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach the AWS managed policy for organization-wide Config access
resource "aws_iam_role_policy_attachment" "config_aggregator" {
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}