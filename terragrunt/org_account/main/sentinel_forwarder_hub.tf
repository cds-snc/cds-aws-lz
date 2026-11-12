# The hub for the Sentinel forwarders' secretless path to the Logs Ingestion API
# (DCE/DCR). It replaces the per-account Cognito pools: one role here, and one
# federated credential in Azure, serve every AWS account.
#
#   forwarder role (any allowed account) -> sts:AssumeRole (this role)
#        -> sts:GetWebIdentityToken, signed by this account's outbound federation
#        -> that JWT as an Entra client assertion
#        -> token for the user-assigned managed identity
#           sentinel-forwarder-v2-aws-hub, built in cds-snc/cds-azure-resources
#        -> POST to the data collection endpoint
#
# Azure checks only the token's issuer and subject (this role's ARN), so this
# role's trust policy is the only thing deciding which accounts can send data.
# Design and decisions: cds-snc/sentinel-connectors,
# docs/aws-forwarder-hub-federation-design.md

locals {
  sentinel_forwarder_hub_role_name = "sentinel-forwarder-hub"

  # What the token is minted for; also the audience of the Azure federated
  # credential.
  sentinel_forwarder_hub_audience = "api://AzureADTokenExchange"

  # terraform-modules//sentinel_forwarder names its role
  # "SentinelForwarderLambda-${var.function_name}". A rename there cuts every
  # forwarder off from the hub with no error, so keep the two in step.
  sentinel_forwarder_hub_caller_pattern = "arn:aws:iam::*:role/SentinelForwarderLambda-*"

  # An allow-list, so an OU added later is denied until someone adds it here.
  # OUs are defined in org_account/organization/organizations.tf.
  sentinel_forwarder_hub_org_id  = "o-625no8z3dd"
  sentinel_forwarder_hub_root_id = "r-5gsq"
  sentinel_forwarder_hub_allowed_ous = {
    Production = "ou-5gsq-vtrsh3ea"
    Staging    = "ou-5gsq-52anzaz7"
    SRETools   = "ou-5gsq-7zshn7gc"
    Security   = "ou-5gsq-vhd3lt42"
  }
}

# Enables IAM outbound identity federation for the Log Archive account and
# exports its issuer URL. Destroying this disables federation and stops every
# forwarder using the hub. Re-enabling returns the same issuer URL, so recovery
# needs no Azure change, but nothing is delivered in between.
resource "aws_iam_outbound_web_identity_federation" "sentinel_forwarder_hub" {
  provider = aws.log_archive

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "sentinel_forwarder_hub_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [local.sentinel_forwarder_hub_org_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.sentinel_forwarder_hub_caller_pattern]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values = [
        for ou in values(local.sentinel_forwarder_hub_allowed_ous) :
        "${local.sentinel_forwarder_hub_org_id}/${local.sentinel_forwarder_hub_root_id}/${ou}/*"
      ]
    }
  }
}

resource "aws_iam_role" "sentinel_forwarder_hub" {
  provider = aws.log_archive

  name               = local.sentinel_forwarder_hub_role_name
  description        = "Mints the Entra client assertion for the Sentinel forwarders. Trusts SentinelForwarderLambda-* roles in the allowed OUs."
  assume_role_policy = data.aws_iam_policy_document.sentinel_forwarder_hub_trust.json

  tags = {
    CostCentre = var.billing_code
  }
}

# The role's only permission: a token for Entra, and nothing else.
data "aws_iam_policy_document" "sentinel_forwarder_hub" {
  statement {
    effect    = "Allow"
    actions   = ["sts:GetWebIdentityToken"]
    resources = ["*"]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "sts:IdentityTokenAudience"
      values   = [local.sentinel_forwarder_hub_audience]
    }

    # The token is only an assertion, exchanged with Entra straight away; the
    # API's own default lifetime is enough. IfExists, so a call that leaves the
    # duration at its default is not denied for lacking the key.
    condition {
      test     = "NumericLessThanEqualsIfExists"
      variable = "sts:DurationSeconds"
      values   = ["300"]
    }
  }
}

resource "aws_iam_role_policy" "sentinel_forwarder_hub" {
  provider = aws.log_archive

  name   = "SentinelForwarderHubGetWebIdentityToken"
  role   = aws_iam_role.sentinel_forwarder_hub.id
  policy = data.aws_iam_policy_document.sentinel_forwarder_hub.json
}

# The two values the Azure federated credential needs (cds-azure-resources).
output "sentinel_forwarder_hub_issuer" {
  description = "Issuer URL of Log Archive's outbound identity federation."
  value       = aws_iam_outbound_web_identity_federation.sentinel_forwarder_hub.issuer_identifier
}

output "sentinel_forwarder_hub_role_arn" {
  description = "ARN of the hub role, the subject of the Azure federated credential."
  value       = aws_iam_role.sentinel_forwarder_hub.arn
}
