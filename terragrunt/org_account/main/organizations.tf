locals {
  root = aws_organizations_organization.org_config.roots[0].id
}

resource "aws_organizations_organizational_unit" "AFT" {
  name      = "AFT"
  parent_id = local.root
}

module "AFT_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.AFT.arn
}

resource "aws_organizations_organizational_unit" "DumpsterFire" {
  name      = "DumpsterFire"
  parent_id = local.root
}

module "DumpsterFire_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.DumpsterFire.arn
}

resource "aws_organizations_organizational_unit" "Production" {
  name      = "Production"
  parent_id = local.root
}

module "Production_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Production.arn
}

resource "aws_organizations_organizational_unit" "Sandbox" {
  name      = "Sandbox"
  parent_id = local.root
}

module "Sandbox_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Sandbox.arn
}

resource "aws_organizations_policy_attachment" "Sandbox-cds_snc_universal_guardrails" {
  policy_id = aws_organizations_policy.cds_snc_universal_guardrails.id
  target_id = aws_organizations_organizational_unit.Sandbox.id
}

resource "aws_organizations_organizational_unit" "Security" {
  name      = "Security"
  parent_id = local.root
}

module "Security_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Security.arn
}

resource "aws_organizations_organizational_unit" "SRETools" {
  name      = "SRETools"
  parent_id = local.root
}

module "SRETools_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.SRETools.arn
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

module "Test_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Test.arn
}
