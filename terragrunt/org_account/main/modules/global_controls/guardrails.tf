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
  regions = toset(["ca-central-1", "us-east-1", "us-west-2"])

  src_map    = [ for ctl in local.strongly_recommend_controls : {"control" = ctl }]
  region_map = [ for region in local.regions : {"region" = region }]

  # Create a list of all possible combinations fo regions and controls
  controls = toset([ for x in setproduct(local.src_map, local.region_map): merge(x...)])
}

resource "aws_controltower_control" "_" {
  for_each = { for control in local.controls: control.control => control}

  control_identifier = "arn:aws:controltower:${each.value.region}::control/${each.value.control}"
  target_identifier  = var.ou_arn

}

