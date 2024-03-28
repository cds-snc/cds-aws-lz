#
# Role used by the cds-snc/site-reliability-engineering/tools/aws-identity-center-audit to read the identitystore, sso and organizations service configurations.
#
# It will be assumed by the GitHub Actions workflow.
#
data "aws_iam_policy_document" "sre_identity_audit_assume" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:role/${local.sre_identity_audit_oidc_role}"
      ]
    }
  }
}

resource "aws_iam_role" "sre_identity_audit" {
  name               = "sre_identity_audit"
  assume_role_policy = data.aws_iam_policy_document.sre_identity_audit_assume.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "sre_identity_audit" {
  version = "2012-10-17"

  statement {
    sid    = "ReadIdentityStore"
    effect = "Allow"
    actions = [
      "identitystore:ListUsers",
      "identitystore:ListGroups",
      "identitystore:ListGroupMemberships"
    ]
    resources = ["arn:aws:identitystore:${var.region}:${var.account_id}:identitystore/*"]
  }

  statement {
    sid    = "ReadSSOAdmin"
    effect = "Allow"
    actions = [
      "sso:DescribeInstance",
      "sso:DescribePermissionSet",
      "sso:ListPermissionSets",
      "sso:ListPermissionSetsProvisionedToAccount",
      "sso:ListAccountAssignments",
      "sso:ListAccountsForProvisionedPermissionSet"

    ]
    resources = ["arn:aws:sso:::instance/*"]
  }

  statement {
    sid    = "ReadOrganizations"
    effect = "Allow"
    actions = [
      "organizations:ListAccounts",
    ]
    resources = ["arn:aws:organizations::${var.account_id}:account/*"]
  }
}

resource "aws_iam_policy" "sre_identity_audit" {
  name   = "sre_identity_audit"
  policy = data.aws_iam_policy_document.sre_identity_audit.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "sre_identity_audit" {
  role       = aws_iam_role.sre_identity_audit.name
  policy_arn = aws_iam_policy.sre_identity_audit.arn
}