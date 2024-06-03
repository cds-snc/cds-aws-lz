module "billing_extract_tags" {
  source      = "github.com/cds-snc/terraform-modules//S3?ref=v9.4.5"
  bucket_name = "5bf89a78-1503-4e02-9621-3ac658f558fb"
  acl         = null

  versioning = {
    enabled = true
  }

  billing_tag_value = var.billing_code
}

resource "aws_s3_bucket_policy" "billing_extract_tags" {
  bucket = module.billing_extract_tags.s3_bucket_id
  policy = data.aws_iam_policy_document.billing_extract_tags_bucket.json
}

data "aws_iam_policy_document" "billing_extract_tags_bucket" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.billing_extract_tags.arn]
    }
    actions = [
      "s3:PutObject*",
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:DeleteObject*",
      "s3:GetBucketLocation"
    ]
    resources = [
      module.billing_extract_tags.s3_bucket_arn,
      "${module.billing_extract_tags.s3_bucket_arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::066023111852:root"]
    }
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      module.billing_extract_tags.s3_bucket_arn,
      "${module.billing_extract_tags.s3_bucket_arn}/*",
    ]
  }
}
