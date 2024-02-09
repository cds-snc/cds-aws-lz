resource "aws_organizations_organization" "org_config" {

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",   # Enabled by Control Tower
    "config.amazonaws.com",       # Enabled by Control Tower
    "sso.amazonaws.com",          # Enabled by Control Tower
    "controltower.amazonaws.com", # Enabled by Control Tower
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "reporting.trustedadvisor.amazonaws.com",
    "account.amazonaws.com",                            # https://docs.aws.amazon.com/accounts/latest/reference/using-orgs-trusted-access.html
    "member.org.stacksets.cloudformation.amazonaws.com" # Enabling to allow CT to re-register OUs
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]

  feature_set = "ALL"
}



locals {
  root = aws_organizations_organization.org_config.roots[0].id
}

resource "aws_organizations_organizational_unit" "AFT" {
  name      = "AFT"
  parent_id = local.root
}


resource "aws_organizations_organizational_unit" "DumpsterFire" {
  name      = "DumpsterFire"
  parent_id = local.root
}


resource "aws_organizations_organizational_unit" "Production" {
  name      = "Production"
  parent_id = local.root
}


resource "aws_organizations_organizational_unit" "Sandbox" {
  name      = "Sandbox"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "SandboxMigration" {
  name      = "SandboxMigration"
  parent_id = local.root
}

resource "aws_organizations_policy_attachment" "Sandbox-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.Sandbox.id
}

resource "aws_organizations_policy_attachment" "Sandbox-PreventEC2Creation" {
  policy_id = aws_organizations_policy.block_ec2.id
  target_id = aws_organizations_organizational_unit.Sandbox.id
}


resource "aws_organizations_policy_attachment" "767397971970-PreventEC2Creation" {
  policy_id = aws_organizations_policy.block_ec2.id
  target_id = "767397971970"
}


resource "aws_organizations_organizational_unit" "Security" {
  name      = "Security"
  parent_id = local.root
}


resource "aws_organizations_organizational_unit" "SRETools" {
  name      = "SRETools"
  parent_id = local.root
}

resource "aws_organizations_organizational_unit" "Staging" {
  name      = "Staging"
  parent_id = local.root
}

module "Staging_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Staging.arn
}

resource "aws_organizations_organizational_unit" "Test" {
  name      = "Test"
  parent_id = local.root
}