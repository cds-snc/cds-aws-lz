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

resource "aws_securityhub_member" "audit" {
  account_id = "886481071419"
  email      = "aws-cloud-pb-ct+sh@cds-snc.ca"
  invite     = true
}

resource "aws_securityhub_invite_accepter" "audit" {
  provider   = aws.audit_log
  depends_on = [aws_securityhub_member.audit]
  master_id  = aws_securityhub_member.audit.master_id
}

resource "aws_securityhub_member" "log_archive" {
  account_id = "274536870005"
  email      = "aws-cloud-pb-ct+sh@cds-snc.ca"
  invite     = true
}

resource "aws_securityhub_invite_accepter" "log_archive" {
  provider   = aws.log_archive
  depends_on = [aws_securityhub_member.log_archive]
  master_id  = aws_securityhub_member.log_archive.master_id
}

resource "aws_securityhub_member" "aft_management" {
  account_id = "137554749751"
  email      = "aws-cloud-pb-ct+sh@cds-snc.ca"
  invite     = true
}

resource "aws_securityhub_invite_accepter" "aft_management" {
  provider   = aws.aft_management
  depends_on = [aws_securityhub_member.aft_management]
  master_id  = aws_securityhub_member.aft_management.master_id
}