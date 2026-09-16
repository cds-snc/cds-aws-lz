# Phase 2 B5 — the AWS half of the Sentinel forwarders' secretless path to the
# Logs Ingestion API (DCE/DCR), replacing the retiring Data Collector API.
#
# The Lambda's IAM role is the only credential involved, and nothing is stored:
#
#   role -> cognito-identity:GetOpenIdTokenForDeveloperIdentity  (this pool)
#        -> that OIDC JWT as an Entra client assertion
#        -> token for the user-assigned managed identity
#           sentinel-forwarder-v2-aws-cognito, built in cds-snc/cds-azure-resources
#        -> POST to the data collection endpoint
#
# The pool has to live in the Lambda's own account. Identity pools carry no
# resource policy, so one cannot be called cross-account — every AWS account
# running a forwarder needs its own pool, and its own federated credential on
# the Azure side.

locals {
  # Also the audience of the Azure federated credential. Matches the name the
  # working jamf forwarder uses, so the two read the same way.
  sentinel_forwarder_cognito_developer_provider_name = "azure-sentinel-access"
}

resource "aws_cognito_identity_pool" "sentinel_forwarder_v2" {
  provider = aws.log_archive

  identity_pool_name               = "sentinel-forwarder-v2-federation"
  allow_unauthenticated_identities = false
  developer_provider_name          = local.sentinel_forwarder_cognito_developer_provider_name

  tags = {
    CostCentre = var.billing_code
  }
}

# The GetOpenIdTokenForDeveloperIdentity grant now comes from the module, which
# builds the same policy on the same role under the same name once
# cognito_identity_pool_id is set (terraform-modules v12.0.0). Keeping this copy
# would put two Terraform resources on one AWS role policy name and let them
# overwrite each other every apply.
#
# Moved rather than removed: the names collide, so a plain destroy-and-create has
# no ordering that guarantees the grant survives — Terraform is free to create
# the module's copy first and then delete this one, which is the same PutRolePolicy
# followed by DeleteRolePolicy. The move is a state edit and touches nothing in AWS.
#
# The GuardDuty forwarder is still not granted: it stays on the Data Collector
# API and sets no cognito_identity_pool_id, so its count is 0.
moved {
  from = aws_iam_role_policy.securityhub_forwarder_cognito
  to   = module.securityhub_forwarder.aws_iam_role_policy.sentinel_forwarder_cognito[0]
}
