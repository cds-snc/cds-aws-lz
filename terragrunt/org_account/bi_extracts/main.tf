module "cur_export_bucket" { 
  source = "github.com/cds-snc/terraform-modules//S3?ref=v9.0.5"
  billing_tag_value = "SRE"
}

import { 
  to = module.cur_export_bucket.aws_s3_bucket.this
  id = "713f18dd-9f30-4976-a152-e81d48cf053a"
}

resource "aws_s3_bucket_policy" "cur_export_bucket" { 
  bucket = module.cur_export_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.cur_export_bucket.json

}

import {
  to = aws_s3_bucket_policy.cur_export_bucket
  id = "713f18dd-9f30-4976-a152-e81d48cf053a"
}

data "aws_iam_policy_document" "cur_export_bucket" {
  statement {
    sid       = "EnableAWSDataExportsToWriteToS3AndCheckPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetBucketPolicy"]
    resources = [
      module.cur_export_bucket.s3_bucket_arn,
      "${module.cur_export_bucket.s3_bucket_arn}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com", "billingreports.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = [
        "arn:aws:cur:us-east-1:659087519042:definition/*",
        "arn:aws:bcm-data-exports:us-east-1:659087519042:export/*"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["659087519042"]
    }
  }

  statement {
    sid       = "CDSSupersetRootRead"
    effect    = "Allow"
    actions   = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      module.cur_export_bucket.s3_bucket_arn,
      "${module.cur_export_bucket.s3_bucket_arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::066023111852:root"]
    }
  }
}