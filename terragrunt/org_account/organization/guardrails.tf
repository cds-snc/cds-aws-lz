## The following guardrails are globally enabled

module "AFT_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.AFT.arn
}

module "DumpsterFire_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.DumpsterFire.arn
}

module "Production_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Production.arn
}

# module "Sandbox_SRC" {
#   source = "./modules/global_controls"
#   ou_arn = aws_organizations_organizational_unit.Sandbox.arn
# }

module "Security_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Security.arn
}

module "SRETools_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.SRETools.arn
}

module "Test_SRC" {
  source = "./modules/global_controls"
  ou_arn = aws_organizations_organizational_unit.Test.arn
}


## The following guardrails are not implemented in all OUs

# [CT.CLOUDTRAIL.PR.2] Require an AWS CloudTrail trail to have log file validation activated
# https://docs.aws.amazon.com/controltower/latest/userguide/cloudtrail-rules.html#ct-cloudtrail-pr-2-description
module "REQUIRE_CLOUDTRAIL_LOG_FILE_VALIDATION" {
  source     = "./modules/control"
  identifier = "KAEEWMVGTQBG"
  ou_arns = [
    aws_organizations_organizational_unit.Test.arn,
    aws_organizations_organizational_unit.SRETools.arn,
    # aws_organizations_organizational_unit.Sandbox.arn,
    aws_organizations_organizational_unit.DumpsterFire.arn,
    aws_organizations_organizational_unit.AFT.arn,
    aws_organizations_organizational_unit.Staging.arn
  ]

  // This control requires CT.CLOUDFORMATION.PR.1 to be enabled
  depends_on = [module.DISALLOW_CFN_EXTENSIONS]
}

# [CT.CLOUDFORMATION.PR.1] Disallow management of resource types, modules, and hooks within the AWS CloudFormation registry
# https://docs.aws.amazon.com/controltower/latest/userguide/elective-controls.html#disallow-cfn-extensions
module "DISALLOW_CFN_EXTENSIONS" {
  source     = "./modules/control"
  identifier = "OMCTIJOASMIZ"
  ou_arns = [
    aws_organizations_organizational_unit.Test.arn,
    aws_organizations_organizational_unit.SRETools.arn,
    aws_organizations_organizational_unit.Security.arn,
    # aws_organizations_organizational_unit.Sandbox.arn,
    aws_organizations_organizational_unit.DumpsterFire.arn,
    aws_organizations_organizational_unit.AFT.arn,
    aws_organizations_organizational_unit.Staging.arn
  ]

}
