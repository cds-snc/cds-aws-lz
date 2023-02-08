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
