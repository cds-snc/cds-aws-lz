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

# Granted as its own role policy rather than folded into the module's. The
# module attaches its base policy with aws_iam_role_policy_attachment and sets
# no managed_policy_arns, so this cannot strip that and that cannot strip this
# — the failure mode cds-aws-lz#449 had to fix on the KMS-decrypt policy.
#
# Only the Security Hub forwarder is granted. The GuardDuty forwarder in
# sentinel_forwarders.tf has no trigger at all and #449 records that it is dead
# code awaiting removal, so giving it a credential would be new reach for
# nothing.
resource "aws_iam_role_policy" "securityhub_forwarder_cognito" {
  provider = aws.log_archive

  name   = "SentinelForwarderCognito-${module.securityhub_forwarder.lambda_name}"
  role   = "SentinelForwarderLambda-${module.securityhub_forwarder.lambda_name}"
  policy = data.aws_iam_policy_document.sentinel_forwarder_v2_cognito.json
}

data "aws_iam_policy_document" "sentinel_forwarder_v2_cognito" {
  statement {
    effect    = "Allow"
    actions   = ["cognito-identity:GetOpenIdTokenForDeveloperIdentity"]
    resources = [aws_cognito_identity_pool.sentinel_forwarder_v2.arn]
  }
}
