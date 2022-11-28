
resource "aws_controltower_control" "ENCRYPTED_VOLUMES"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_ENCRYPTED_VOLUMES"
}

resource "aws_controltower_control" "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
}

resource "aws_controltower_control" "RDS_SNAPSHOTS_PUBLIC_PROHIBITED"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_RDS_SNAPSHOTS_PUBLIC_PROHIBITED"
}

resource "aws_controltower_control" "RESTRICTED_COMMON_PORTS"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_RESTRICTED_COMMON_PORTS"
}

resource "aws_controltower_control" "RESTRICTED_SSH"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_RESTRICTED_SSH"
}

resource "aws_controltower_control" "ROOT_ACCOUNT_MFA_ENABLED"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_ROOT_ACCOUNT_MFA_ENABLED"
}

resource "aws_controltower_control" "S3_BUCKET_PUBLIC_READ_PROHIBITED"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED"
}

resource "aws_controltower_control" "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
}

resource "aws_controltower_control" "DETECT_CLOUDTRAIL_ENABLED_ON_MEMBER_ACCOUNTS"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_DETECT_CLOUDTRAIL_ENABLED_ON_MEMBER_ACCOUNTS"
}

resource "aws_controltower_control" "RDS_STORAGE_ENCRYPTED"{
  target_identifier = var.ou_arn
  control_identifier = "arn:aws:controltower:ca-central-1::control/AWS-GR_RDS_STORAGE_ENCRYPTED"
}
