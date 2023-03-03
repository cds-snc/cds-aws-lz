data "aws_iam_policy_document" "cartography_tmp_scp" {
  statement {
    sid    = "GRREGIONDENYreplication"
    effect = "Deny"
    not_actions = [
      "a4b:*",
      "access-analyzer:*",
      "acm:*",
      "account:*",
      "activate:*",
      "artifact:*",
      "aws-marketplace-management:*",
      "aws-marketplace:*",
      "aws-portal:*",
      "billingconductor:*",
      "budgets:*",
      "ce:*",
      "chatbot:*",
      "chime:*",
      "cloudfront:*",
      "compute-optimizer:*",
      "config:*",
      "cur:*",
      "datapipeline:GetAccountLimits",
      "devicefarm:*",
      "directconnect:*",
      "discovery-marketplace:*",
      "ec2:DescribeRegions",
      "ec2:DescribeTransitGateways",
      "ec2:DescribeVpnGateways",
      "ecr-public:*",
      "fms:*",
      "globalaccelerator:*",
      "health:*",
      "iam:*",
      "importexport:*",
      "kms:*",
      "license-manager:ListReceivedLicenses",
      "lightsail:Get*",
      "mobileanalytics:*",
      "networkmanager:*",
      "organizations:*",
      "pricing:*",
      "resource-explorer-2:*",
      "route53-recovery-cluster:*",
      "route53-recovery-control-config:*",
      "route53-recovery-readiness:*",
      "route53:*",
      "route53domains:*",
      "s3:CreateMultiRegionAccessPoint",
      "s3:DeleteMultiRegionAccessPoint",
      "s3:DescribeMultiRegionAccessPointOperation",
      "s3:GetAccountPublic",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetMultiRegionAccessPoint",
      "s3:GetMultiRegionAccessPointPolicy",
      "s3:GetMultiRegionAccessPointPolicyStatus",
      "s3:GetStorageLensConfiguration",
      "s3:GetStorageLensDashboard",
      "s3:ListAllMyBuckets",
      "s3:ListMultiRegionAccessPoints",
      "s3:ListStorageLensConfigurations",
      "s3:PutAccountPublic",
      "s3:PutAccountPublicAccessBlock",
      "s3:PutMultiRegionAccessPointPolicy",
      "savingsplans:*",
      "shield:*",
      "sso:*",
      "sts:*",
      "support:*",
      "supportapp:*",
      "supportplans:*",
      "sustainability:*",
      "tag:GetResources",
      "trustedadvisor:*",
      "vendor-insights:ListEntitledSecurityProfiles",
      "waf-regional:*",
      "waf:*",
      "wafv2:*"
    ]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values = [
        "us-east-1",
        "us-west-2",
        "ca-central-1",
      ]
    }
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values = ["arn:aws:iam::*:role/AWSControlTowerExecution",
      "arn:aws:iam::*:role/secopsAssetInventorySecurityAuditRole"]
    }
  }

  statement {
    sid    = "PreventIAMRoleModifications"
    effect = "Deny"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:CreateRole",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateRolePolicy"
    ]
    resources = [
      "arn:aws:iam::*:role/secopsAssetInventorySecurityAuditRole"
    ]
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::*:role/AWSAFTExecution"
      ]
    }
  }

  statement {
    sid    = "PreventIAMAccessKeyCreation"
    effect = "Deny"
    actions = [
      "iam:CreateAccessKey",
     ]
    resources = [
      "arn:aws:iam::*:role/secopsAssetInventorySecurityAuditRole"
    ]
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::*:role/AWSAFTExecution"
      ]
    }
  }
}

resource "aws_organizations_policy" "cartography_tmp_scp" {
  name    = "Cartography Temporary SCP"
  type    = "SERVICE_CONTROL_POLICY"
  content = data.aws_iam_policy_document.cartography_tmp_scp.json
}

data "aws_iam_policy_document" "cds_snc_universal_guardrails" {
  statement {
    sid    = "BlockRedshift"
    effect = "Deny"
    actions = [
      "redshift:*",
      "redshift-serverless:*",
      "redshift-data:*"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "BlockSageMaker"
    effect = "Deny"
    actions = [
      "sagemaker:*"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "ProtectInternalSreAlertTopic"
    effect = "Deny"
    actions = [
      "sns:DeleteTopic"
    ]
    resources = [
      "arn:aws:sns:*:*:internal-sre-alert",
    ]
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::*:role/AWSAFTExecution",
      ]
    }
  }

  statement {
    sid    = "DoNotAllowOpsUsersToBeDeleted"
    effect = "Deny"
    actions = [
      "iam:DeleteUser"
    ]
    resources = [
      "arn:aws:iam::*:user/ops1",
      "arn:aws:iam::*:user/ops2"
    ]
  }

  statement {
    sid    = "DoNotAllowIAMKeysOnOpsUsers"
    effect = "Deny"
    actions = [
      "iam:CreateAccessKey"
    ]
    resources = [
      "arn:aws:iam::*:user/ops1",
      "arn:aws:iam::*:user/ops2"
    ]
  }

  statement {
    sid    = "DoNotAllowLeaveOrg"
    effect = "Deny"
    actions = [
      "organizations:LeaveOrganization"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "ProtectSecuritySettings"
    effect = "Deny"
    actions = [
      "access-analyzer:DeleteAnalyzer",
      "ec2:DisableEbsEncryptionByDefault",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "DenyRootActions"
    effect = "Deny"
    not_actions = [


      ## Allow Account Actions for accounts created before Mar 6 2023
      ## see https://docs.aws.amazon.com/accounts/latest/reference/security_account-permissions-ref.html
      "aws-portal:*",

      ## Allow changing of account settings
      "account:PutChallengeQuestions",
      "account:CloseAccount",
      "account:PutContactInformation",
      "account:Get*",
      "account:List*",

      ## Allow changing of account name 
      "iam:UpdateAccountName",

      ### Enable MFA 
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "iam:DeleteVirtualMFADevice",


      ## Allow us to attach admin to the IAM Users accounts if required
      "iam:GetPolicy",
      "iam:ListPolicies",
      "iam:PutPolicy",
      "iam:AttachUserPolicy",
      "iam:ListAttachedUserPolicies",
      "iam:AttachGroupPolicy",
      "iam:ListAttachedGroupPolicies",

      "sts:GetSessionToken",

    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }

}

resource "aws_organizations_policy" "cds_snc_universal_guardrails" {
  name    = "CDS-SNC Universal Guardrails"
  type    = "SERVICE_CONTROL_POLICY"
  content = data.aws_iam_policy_document.cds_snc_universal_guardrails.json
}
