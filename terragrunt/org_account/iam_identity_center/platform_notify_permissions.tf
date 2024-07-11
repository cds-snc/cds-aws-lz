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
#  Route 53
#
resource "aws_ssoadmin_permission_set" "admin_route53_notify_hosted_zone" {
  name         = "Route53-NotifyHostedZone-RecordSets-Admin"
  description  = "Grants full access to the Notify hosted zone's record sets in Route 53."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "admin_route53_notify_hosted_zone" {
  permission_set_arn = aws_ssoadmin_permission_set.admin_route53_notify_hosted_zone.arn
  inline_policy      = data.aws_iam_policy_document.admin_route53_notify_hosted_zone.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "admin_route53_notify_hosted_zone" {
  statement {
    sid    = "ListHostedZones"
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:GetHostedZoneCount",
      "route53:ListHostedZonesByName"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "UpdateNotifyHostedZoneRecordSets"
    effect = "Allow"
    actions = [
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
      "route53:GetChange"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/Z1XG153PQF3VV5"
    ]
  }
}