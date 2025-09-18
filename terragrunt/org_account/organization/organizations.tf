resource "aws_organizations_organization" "org_config" {

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",   # Enabled by Control Tower
    "config.amazonaws.com",       # Enabled by Control Tower
    "sso.amazonaws.com",          # Enabled by Control Tower
    "controltower.amazonaws.com", # Enabled by Control Tower
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "reporting.trustedadvisor.amazonaws.com",
    "account.amazonaws.com",                             # https://docs.aws.amazon.com/accounts/latest/reference/using-orgs-trusted-access.html
    "member.org.stacksets.cloudformation.amazonaws.com", # Enabling to allow CT to re-register OUs
    "auditmanager.amazonaws.com",                        # Required for Audit Manager to work with Organizations and for SSC's CaC soltuion 
    "config-multiaccountsetup.amazonaws.com"             # Required for Config Multi Account Setup to work with Organizations and for SSC's CaC solution
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

resource "aws_organizations_policy_attachment" "AFT-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.AFT.id
}


resource "aws_organizations_organizational_unit" "DumpsterFire" {
  name      = "DumpsterFire"
  parent_id = local.root
}

resource "aws_organizations_policy_attachment" "DumpsterFire-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.DumpsterFire.id
}

resource "aws_organizations_organizational_unit" "Production" {
  name      = "Production"
  parent_id = local.root
}

resource "aws_organizations_policy_attachment" "Production-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.Production.id
}

resource "aws_organizations_organizational_unit" "Sandbox" {
  name      = "Sandbox"
  parent_id = local.root
}

resource "aws_organizations_policy_attachment" "Sandbox-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.Sandbox.id
}

resource "aws_organizations_policy_attachment" "Sandbox-aws_nuke_guardrails" {
  policy_id = aws_organizations_policy.aws_nuke_guardrails.id
  target_id = aws_organizations_organizational_unit.Sandbox.id
}


resource "aws_organizations_organizational_unit" "Security" {
  name      = "Security"
  parent_id = local.root
}

resource "aws_organizations_policy_attachment" "Security-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.Security.id
}

resource "aws_organizations_organizational_unit" "SRETools" {
  name      = "SRETools"
  parent_id = local.root
}

resource "aws_organizations_policy_attachment" "SRETools-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.SRETools.id
}

resource "aws_organizations_organizational_unit" "Staging" {
  name      = "Staging"
  parent_id = local.root
}

module "Staging_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Staging.arn
}

resource "aws_organizations_policy_attachment" "Staging-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.Staging.id
}

resource "aws_organizations_organizational_unit" "Test" {
  name      = "Test"
  parent_id = local.root
}

resource "aws_organizations_policy_attachment" "Test-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.Test.id
}

resource "aws_organizations_policy_attachment" "Test-aws_nuke_guardrails" {
  policy_id = aws_organizations_policy.aws_nuke_guardrails.id
  target_id = aws_organizations_organizational_unit.Test.id
}

resource "aws_organizations_policy_attachment" "DumpsterFire-qurantine_deny_all_policy" {
  policy_id = aws_organizations_policy.qurantine_deny_all_policy.id
  target_id = aws_organizations_organizational_unit.DumpsterFire.id
}