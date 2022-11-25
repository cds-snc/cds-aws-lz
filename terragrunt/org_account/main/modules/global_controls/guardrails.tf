locals {
  strongly_recommend_controls = toset(["AWS-GR_ENCRYPTED_VOLUMES",
    "AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK",
    "AWS-GR_RDS_SNAPSHOTS_PUBLIC_PROHIBITED",
    "AWS-GR_RESTRICTED_COMMON_PORTS",
    "AWS-GR_RESTRICTED_SSH",
    "AWS-GR_ROOT_ACCOUNT_MFA_ENABLED",
    "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED",
    "AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED",
    "AWS-GR_DETECT_CLOUDTRAIL_ENABLED_ON_MEMBER_ACCOUNTS",
    "AWS-GR_RDS_STORAGE_ENCRYPTED"
  ])
}

resource "aws_controltower_control" "ca_central_1" {
  for_each = local.strongly_recommend_controls

  control_identifier = "arn:aws:controltower:ca-central-1::control/${each.value}"
  target_identifier  = var.ou_arn

}

resource "aws_controltower_control" "us_east_1" {
  for_each = local.strongly_recommend_controls

  control_identifier = "arn:aws:controltower:us-east-1::control/${each.value}"
  target_identifier  = var.ou_arn

}

resource "aws_controltower_control" "us_west_2" {
  for_each = local.strongly_recommend_controls

  control_identifier = "arn:aws:controltower:us-west-2::control/${each.value}"
  target_identifier  = var.ou_arn

}
