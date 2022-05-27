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

resource "aws_securityhub_account" "org" {}

resource "aws_securityhub_member" "org" {
  provider = aws.log_archive

  account_id = var.org_account

  email  = "aws-cloud-pb-ct+sh@cds-snc.ca"
  invite = true

  depends_on = [aws_securityhub_account.org]

}

resource "aws_securityhub_invite_accepter" "org" {
  master_id  = aws_securityhub_member.org.master_id
  depends_on = [aws_securityhub_member.org]
}

# audit 
resource "aws_securityhub_account" "audit" {
  provider = aws.audit_log
}

resource "aws_securityhub_member" "audit" {
  provider = aws.log_archive

  account_id = "886481071419"
  email      = "aws-cloud-pb-ct+sh@cds-snc.ca"
  invite     = true

  depends_on = [aws_securityhub_account.audit]
}

resource "aws_securityhub_invite_accepter" "audit" {
  provider   = aws.audit_log
  master_id  = aws_securityhub_member.audit.master_id
  depends_on = [aws_securityhub_member.audit]
}

# aft_management


resource "aws_securityhub_account" "aft_management" {
  provider = aws.aft_management
}

resource "aws_securityhub_member" "aft_management" {
  provider = aws.log_archive

  account_id = "137554749751"
  email      = "aws-cloud-pb-ct+sh@cds-snc.ca"
  invite     = true

  depends_on = [aws_securityhub_account.aft_management]
}

resource "aws_securityhub_invite_accepter" "aft_management" {
  provider   = aws.aft_management
  master_id  = aws_securityhub_member.aft_management.master_id
  depends_on = [aws_securityhub_member.aft_management]
}

