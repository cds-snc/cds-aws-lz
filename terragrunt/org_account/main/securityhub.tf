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



# invites

resource "aws_securityhub_account" "audit" {
  provider = aws.audit_log
}


resource "aws_securityhub_account" "log_archive" {
  provider = aws.log_archive
}

resource "aws_securityhub_account" "aft_management" {
  provider = aws.aft_management
}
