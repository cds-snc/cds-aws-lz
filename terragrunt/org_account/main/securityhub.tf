resource "aws_securityhub_organization_admin_account" "admin_account" {
  admin_account_id = local.admin_account
}

resource "aws_securityhub_organization_configuration" "sh" {
  provider = aws.log_archive

  auto_enable = true

  depends_on = [aws_securityhub_organization_admin_account.admin_account]
}

# Enable CIS foundations benchmark
resource "aws_securityhub_standards_subscription" "cis_aws_foundations_benchmark" {
  provider = aws.log_archive

  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"

  depends_on = [aws_securityhub_organization_admin_account.admin_account]
}

module "org" {
  source = "../../modules/existing_security_hub_member"
  providers = {
    aws.admin = aws.log_archive
    aws.member = aws
  }

  email  = "aws-cloud-pb-ct+sh@cds-snc.ca"
}

module "audit" {
  source = "../../modules/existing_security_hub_member"
  providers = {
    aws.admin = aws.log_archive
    aws.member = aws.audit_log
  }

  email  = "aws-cloud-pb-ct+sh@cds-snc.ca"
}

module "aft_managment" {
  source = "../../modules/existing_security_hub_member"
  providers = {
    aws.admin = aws.log_archive
    aws.member = aws.aft_management
  }

  email  = "aws-cloud-pb-ct+sh@cds-snc.ca"
}
