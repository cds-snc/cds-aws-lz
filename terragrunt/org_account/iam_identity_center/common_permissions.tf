#
# These are permission sets that are shared by multiple products.
#

#
# Billing read-only
#
resource "aws_ssoadmin_permission_set" "read_only_billing" {
  name         = "Billing-ReadOnly"
  description  = "Grants read-only access to billing data."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "read_only_billing" {
  permission_set_arn = aws_ssoadmin_permission_set.read_only_billing.arn
  inline_policy      = data.aws_iam_policy_document.read_only_billing.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "read_only_billing" {
  statement {
    sid    = "BillingRead"
    effect = "Allow"
    actions = [
      "billing:Get*",
      "billing:List*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CostExplorerRead"
    effect = "Allow"
    actions = [
      "ce:Describe*",
      "ce:Get*",
      "ce:List*"
    ]
    resources = ["*"]
  }
}

#
# Support Center admin
#
resource "aws_ssoadmin_permission_set" "admin_support_center" {
  name         = "SupportCenter-Admin"
  description  = "Grants full access to Support Center, manage SES/SMS suppressions and read-only CloudWatch."
  instance_arn = local.sso_instance_arn
}

locals {
  support_center_admin_managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AWSSupportAccess",
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  ])
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_support_center" {
  for_each           = local.support_center_admin_managed_policy_arns
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = each.key
  permission_set_arn = aws_ssoadmin_permission_set.admin_support_center.arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "admin_support_center" {
  permission_set_arn = aws_ssoadmin_permission_set.admin_support_center.arn
  inline_policy      = data.aws_iam_policy_document.admin_support_center.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "admin_support_center" {
  statement {
    sid    = "SESReadAndDeleteSuppressed"
    effect = "Allow"
    actions = [
      "ses:Get*",
      "ses:List*",
      "ses:DeleteSuppressedDestination"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SNSListAndDeleteOptedOutNumbers"
    effect = "Allow"
    actions = [
      "sns:CheckIfPhoneNumberIsOptedOut",
      "sns:ListPhoneNumbersOptedOut",
      "sns:OptInPhoneNumber"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PinpointListAndDeleteOptedOutNumbers"
    effect = "Allow"
    actions = [
      "sms-voice:DeleteOptedOutNumber",
      "sms-voice:DescribeOptOutLists",
      "sms-voice:DescribeOptedOutNumbers",
      "sms-voice:PutOptedOutNumber"
    ]
    resources = ["*"]
  }
}

#
# QuickSight
#
resource "aws_ssoadmin_permission_set" "quicksight" {
  name         = "Quicksight"
  description  = "Grants access to Quicksight without giving the ability to manage users or the subscription level."
  instance_arn = local.sso_instance_arn
}

locals {
  quicksight_managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/service-role/AWSQuicksightAthenaAccess",
    "arn:aws:iam::aws:policy/service-role/AWSQuickSightDescribeRDS",
    "arn:aws:iam::aws:policy/service-role/AWSQuickSightDescribeRedshift",
    "arn:aws:iam::aws:policy/service-role/AWSQuickSightElasticsearchPolicy",
    "arn:aws:iam::aws:policy/AWSQuickSightIoTAnalyticsAccess",
    "arn:aws:iam::aws:policy/service-role/AWSQuickSightListIAM",
    "arn:aws:iam::aws:policy/service-role/AWSQuicksightOpenSearchPolicy",
    "arn:aws:iam::aws:policy/service-role/AWSQuickSightTimestreamPolicy",
    "arn:aws:iam::aws:policy/service-role/QuickSightAccessForS3StorageManagementAnalyticsReadOnly"
  ])
}

resource "aws_ssoadmin_managed_policy_attachment" "quicksight" {
  for_each           = local.quicksight_managed_policy_arns
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = each.key
  permission_set_arn = aws_ssoadmin_permission_set.quicksight.arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "quicksight" {
  permission_set_arn = aws_ssoadmin_permission_set.quicksight.arn
  inline_policy      = data.aws_iam_policy_document.quicksight.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "quicksight" {
  statement {
    sid    = "QuickSightAccess"
    effect = "Allow"
    actions = [
      "quicksight:*"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "QuickSightGuardrails"
    effect = "Deny"
    actions = [
      "quicksight:CreateAdmin",
      "quicksight:DeleteAccountSubscription",
      "quicksight:DeleteUser",
      "quicksight:DeleteUserByPrincipalId",
      "quicksight:DeleteVPCConnection",
      "quicksight:Subscribe",
      "quicksight:Unsubscribe",
      "quicksight:UpdateAccountSettings",
      "quicksight:UpdateUser",
      "quicksight:UpdateVPCConnection",
    ]
    resources = ["*"]
  }
}
