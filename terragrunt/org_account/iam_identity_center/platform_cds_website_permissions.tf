#
# Canadian Digital Service website admin
#
resource "aws_ssoadmin_permission_set" "canadian_digital_service_production_website_admin" {
  name         = "CDSWebsite-Admin"
  description  = "Grants admin access to the Canadian Digital Service's account resources that are used by the main CDS website."
  instance_arn = local.sso_instance_arn
}

locals {
  canadian_digital_service_production_website_admin_policy_arns = toset([
    "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess",
    "arn:aws:iam::aws:policy/AWSWAFFullAccess",
    "arn:aws:iam::aws:policy/CloudFrontFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccessV2",
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ])
}

resource "aws_ssoadmin_managed_policy_attachment" "canadian_digital_service_production_website_admin" {
  for_each           = local.canadian_digital_service_production_website_admin_policy_arns
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = each.key
  permission_set_arn = aws_ssoadmin_permission_set.canadian_digital_service_production_website_admin.arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "canadian_digital_service_production_website_admin" {
  permission_set_arn = aws_ssoadmin_permission_set.canadian_digital_service_production_website_admin.arn
  inline_policy      = data.aws_iam_policy_document.canadian_digital_service_production_website_admin.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "canadian_digital_service_production_website_admin" {
  statement {
    sid    = "S3ListBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "S3ReadWriteWebsiteDistObjects"
    effect = "Allow"
    actions = [
      "s3:Describe*",
      "s3:DeleteObject*",
      "s3:Get*",
      "s3:List*",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::cds-website-english-dist",
      "arn:aws:s3:::cds-website-english-dist/*",
      "arn:aws:s3:::cds-website-french-dist",
      "arn:aws:s3:::cds-website-french-dist/*"
    ]
  }
}
