#
# Role used by the security team to automate config and security hub findings and pull data into a report.
#
# It will be assumed by the GitHub Actions workflow.
#

# Policy document to allow only to get the compliance summary by resource type and list findings 
data "aws_iam_policy_document" "security_oscal_report" {
  version = "2012-10-17"

  statement {
    sid    = "ReadConfig"
    effect = "Allow"
    actions = [
      "config:GetComplianceSummaryByResourceType",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ReadSecurityHub"
    effect = "Allow"
    actions = [
      "securityhub:*",
    ]
    resources = ["*"]
  }
}

# Policy for the role to assume the role
resource "aws_iam_policy" "security_oscal_report" {
  name   = "security_oscal_report"
  policy = data.aws_iam_policy_document.security_oscal_report.json

  tags = local.common_tags
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "security_oscal_report" {
  role       = local.security_oscal_report_oidc_role
  policy_arn = aws_iam_policy.security_oscal_report.arn
}
