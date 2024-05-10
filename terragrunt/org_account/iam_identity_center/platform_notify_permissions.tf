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
# Pinpoint SMS admin
#
resource "aws_ssoadmin_permission_set" "admin_pinpoint_sms" {
  name         = "Pinpoint-SMS-Admin"
  description  = "Grants full access to Pinpoint SMS Voice."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "admin_pinpoint_sms" {
  permission_set_arn = aws_ssoadmin_permission_set.admin_pinpoint_sms.arn
  inline_policy      = data.aws_iam_policy_document.admin_pinpoint_sms.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "admin_pinpoint_sms" {
  statement {
    sid    = "DataRead"
    effect = "Allow"
    actions = [
      "firehose:ListDeliveryStreams",
      "iam:ListRoles",
      "kinesis:ListStreams",
      "mobiletargeting:Get*",
      "mobiletargeting:List*",
      "s3:List*",
      "ses:Describe*",
      "ses:Get*",
      "ses:List*",
      "sns:ListTopics"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SMSVoiceFullAccess"
    effect = "Allow"
    actions = [
      "sms-voice:*"
    ]
    resources = ["*"]
  }
}

#
# SSM session connection to the Blazer ECS task
#
resource "aws_ssoadmin_permission_set" "notify_access_ecs_blazer" {
  name         = "ECS-Blazer-Access"
  description  = "Grants access to the Blazer ECS task using an SSM session."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "notify_access_ecs_blazer" {
  permission_set_arn = aws_ssoadmin_permission_set.notify_access_ecs_blazer.arn
  inline_policy      = data.aws_iam_policy_document.notify_access_ecs_blazer.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "notify_access_ecs_blazer" {
  statement {
    sid    = "SSMSessionStartBlazer"
    effect = "Allow"
    actions = [
      "ssm:StartSession"
    ]
    resources = [
      "arn:aws:ssm:ca-central-1::document/AWS-StartPortForwardingSession",
      "arn:aws:ecs:ca-central-1:*:task/blazer/*"
    ]
  }

  statement {
    sid    = "SSMSessionManage"
    effect = "Allow"
    actions = [
      "ssm:TerminateSession",
      "ssm:ResumeSession"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSTaskBlazerRead"
    effect = "Allow"
    actions = [
      "ecs:ListTasks",
      "ecs:DescribeTasks"
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:ca-central-1:*:cluster/blazer"
      ]
    }
  }
}

#
# QuickSight
#
resource "aws_ssoadmin_permission_set" "admin_s3_website_assets" {
  name         = "S3-NotifyWebsiteAssets-Admin"
  description  = "Grants full access to the S3 buckets used for the Notify website assets."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "admin_s3_website_assets" {
  permission_set_arn = aws_ssoadmin_permission_set.admin_s3_website_assets.arn
  inline_policy      = data.aws_iam_policy_document.admin_s3_website_assets.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "admin_s3_website_assets" {
  statement {
    sid    = "ListAllOwnedS3Buckets"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ListS3AssetBuckets"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::notification-alpha-canada-ca-asset-upload",
      "arn:aws:s3:::notification-canada-ca-production-asset-upload",
      "arn:aws:s3:::notification-canada-ca-staging-asset-upload"
    ]
  }

  statement {
    sid    = "AdminS3AssetBucketObjects"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::notification-alpha-canada-ca-asset-upload/*",
      "arn:aws:s3:::notification-canada-ca-production-asset-upload/*",
      "arn:aws:s3:::notification-canada-ca-staging-asset-upload/*"
    ]
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
