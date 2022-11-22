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
    sid    = "DoNotAllowIAMUsersOtherThanOps"
    effect = "Deny"
    actions = [
      "iam:CreateUser"
    ]
    not_resources = [
      "arn:aws:iam::*:user/ops1",
      "arn:aws:iam::*:user/ops2"
    ]
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
}

resource "aws_organizations_policy" "cds_snc_universal_guardrails" {
  name    = "CDS-SNC Universal Guardrails"
  type    = "SERVICE_CONTROL_POLICY"
  content = data.aws_iam_policy_document.cds_snc_universal_guardrails.json
}