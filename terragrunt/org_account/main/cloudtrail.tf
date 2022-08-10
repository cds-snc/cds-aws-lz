data "aws_s3_bucket" "org_logging" { 
  provider = aws.log_archive

  bucket = "aws-controltower-logs-274536870005-ca-central-1"
}


data "aws_iam_policy_document" "rep_role" { 
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [ "sts:AssumeRole" ]

  }
}

resource "aws_iam_role" "replication" {
  name = "orgCtReplication"

  assume_role_policy = data.aws_iam_policy_document.rep_role.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_iam_policy" "replication" { 
  name = "ct-cbs-replication-policy"
  policy = data.aws_iam_policy_document.ct_replication.json
}

data "aws_iam_policy_document" "ct_replication" {

  statement {
    effect = "Allow"
    resources = [data.aws_s3_bucket.org_logging.arn]
    actions = [
      "s3:GetReplicationConfiguration", 
      "s3:ListBucket"
    ]
  }

  statement { 
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = ["${aws_s3_bucket.source.arn}/*"]
  }

  statement {

    actions = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
    ]

    resource = ["${local.destination_bucket_arn}/*"]
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" { 
  provider = aws.log_archive

  bucket = data.aws_s3_bucket.org_logging.id

  rule { 
    id = "cbs_cloudtrail_logs"

    destination {
      access_control_translation = "Destination"
      bucket = local.destination_bucket_arn
      account_id = local.destination_account_id
      encryption_configuration {
        replica_kms_key_id = local.destination_kms_key_id
      }
    }

    filter {
      prefix = ""
    }
  }

}


locals { 
  destination_bucket_arn = "arn:aws:s3:::cbs-log-archive-871282759583"
  destination_kms_key_arn = "arn:aws:kms:ca-central-1:871282759583:key/c4591f87-9445-4840-acb6-a5569e703c93"
  destination_account_id = ""
}