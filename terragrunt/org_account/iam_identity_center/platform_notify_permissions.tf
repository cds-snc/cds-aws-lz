#
# Pinpoint SMS admin
#
resource "aws_ssoadmin_permission_set" "admin_pointpoint_sms" {
  name         = "Admin-Pinpoint-SMS"
  description  = "Grants full access to Pinpoint SMS Voice."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "admin_pointpoint_sms" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_pointpoint_sms.arn
  customer_managed_policy_reference {
    name = aws_iam_policy.admin_pointpoint_sms.name
    path = aws_iam_policy.admin_pointpoint_sms.path
  }
}

resource "aws_iam_policy" "admin_pointpoint_sms" {
  name        = "Admin-Pinpoint-SMS"
  path        = "/identity-center/notify/"
  description = "Full access to Pointpoint SMS Voice."
  policy      = data.aws_iam_policy_document.admin_pointpoint_sms.json
}

data "aws_iam_policy_document" "admin_pointpoint_sms" {
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
  name         = "Notify-Access-ECS-Blazer"
  description  = "Grants access to the Blazer ECS task using an SSM session."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "notify_access_ecs_blazer" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.notify_access_ecs_blazer.arn
  customer_managed_policy_reference {
    name = aws_iam_policy.notify_access_ecs_blazer.name
    path = aws_iam_policy.notify_access_ecs_blazer.path
  }
}

resource "aws_iam_policy" "notify_access_ecs_blazer" {
  name        = "Notify-Access-ECS-Blazer"
  path        = "/identity-center/notify/"
  description = "Manage SSM sessions to connect to the Blazer ECS Task."
  policy      = data.aws_iam_policy_document.notify_access_ecs_blazer.json
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
      test     = "arn_like"
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
  name         = "Admin-S3-WebsiteAssets"
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "admin_s3_website_assets" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_s3_website_assets.arn
  customer_managed_policy_reference {
    name = aws_iam_policy.admin_s3_website_assets.name
    path = aws_iam_policy.admin_s3_website_assets.path
  }
}

resource "aws_iam_policy" "admin_s3_website_assets" {
  name        = "Admin-S3-WebsiteAssets"
  path        = "/identity-center/notify/"
  description = "Grants ability to manage the Notify S3 website assets."
  policy      = data.aws_iam_policy_document.admin_s3_website_assets.json
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
  name         = "Admin-SupportCenter"
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

resource "aws_ssoadmin_customer_managed_policy_attachment" "ses_sns_manage_suppressed" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_support_center.arn
  customer_managed_policy_reference {
    name = aws_iam_policy.remove_ses_sns_suppressed.name
    path = aws_iam_policy.remove_ses_sns_suppressed.path
  }
}

resource "aws_iam_policy" "remove_ses_sns_suppressed" {
  name        = "Remove-SES-SNS-Suppressed"
  path        = "/identity-center/notify/"
  description = "Remove SES and SNS suppressed phone numbers and email addresses."
  policy      = data.aws_iam_policy_document.remove_ses_sns_suppressed.json
}

data "aws_iam_policy_document" "remove_ses_sns_suppressed" {
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
resource "aws_ssoadmin_permission_set" "access_quicksight" {
  name         = "Access-QuickSight"
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

resource "aws_ssoadmin_managed_policy_attachment" "access_quicksight" {
  for_each           = local.quicksight_managed_policy_arns
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = each.key
  permission_set_arn = aws_ssoadmin_permission_set.access_quicksight.arn
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "access_quicksight" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.access_quicksight.arn
  customer_managed_policy_reference {
    name = aws_iam_policy.access_quicksight.name
    path = aws_iam_policy.access_quicksight.path
  }
}

resource "aws_iam_policy" "access_quicksight" {
  name        = "Access-QuickSight"
  path        = "/identity-center/notify/"
  description = "Grants access to QuickSight."
  policy      = data.aws_iam_policy_document.access_quicksight.json
}

data "aws_iam_policy_document" "access_quicksight" {
  statement {
    sid    = "QuickSightAccess"
    effect = "Allow"
    actions = [
      "quicksight:CreateAnalysis",
      "quicksight:CreateDashboard",
      "quicksight:CreateDataSet",
      "quicksight:CreateFolder",
      "quicksight:CreateFolderMembership",
      "quicksight:DeleteAnalysis",
      "quicksight:DeleteDashboard",
      "quicksight:DeleteDataSet",
      "quicksight:DeleteFolder",
      "quicksight:DeleteFolderMembership",
      "quicksight:Describe*",
      "quicksight:Get*",
      "quicksight:List*",
      "quicksight:Pass*",
      "quicksight:RestoreAnalysis",
      "quicksight:Search*",
      "quicksight:Search*",
      "quicksight:TagResource",
      "quicksight:UntagResource",
      "quicksight:UpdateAnalysis",
      "quicksight:UpdateDashboard",
      "quicksight:UpdateDataSet",
      "quicksight:UpdateFolder",
      "quicksight:UpdateFolderMembership",
    ]
    resources = ["*"]
  }
}
