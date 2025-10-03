#
# CRA Bucket GetObject Permissions
#

resource "aws_ssoadmin_permission_set" "cra_bucket_get_object" {
  name         = "CRABucket-GetObject"
  description  = "Grants read-only access to the CRA S3 bucket."
  instance_arn = local.sso_instance_arn
}


resource "aws_ssoadmin_permission_set_inline_policy" "cra_bucket_get_object" {
  permission_set_arn = aws_ssoadmin_permission_set.cra_bucket_get_object.arn
  inline_policy      = data.aws_iam_policy_document.cra_bucket_get_object.json
  instance_arn       = local.sso_instance_arn
}


data "aws_iam_policy_document" "cra_bucket_get_object" {
  statement {
    sid    = "AllowDataBucketReadAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::cra-upd-dashboard-data-staging/*",
      "arn:aws:s3:::cra-upd-dashboard-data-staging"
    ]
  }
}
