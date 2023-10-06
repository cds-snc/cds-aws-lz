#
# Role used by the cds-snc/site-reliability-engineering/tools/aws-security-hub-automation-rules to 
# manage Security Hub automation rules.
#
# It will be assumed by the GitHub Actions workflow.
#

data "aws_iam_policy_document" "sre_sechub_automation_rules" {
  version = "2012-10-17"

  statement {
    sid    = "ManageSecurityHubAutomationRules"
    effect = "Allow"
    actions = [
      "securityhub:BatchDeleteAutomationRules",
      "securityhub:BatchGetAutomationRules",
      "securityhub:CreateAutomationRule",
      "securityhub:ListAutomationRules"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sre_sechub_automation_rules" {
  name   = "sre_sechub_automation_rules"
  policy = data.aws_iam_policy_document.sre_sechub_automation_rules.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "sre_sechub_automation_rules" {
  role       = aws_iam_role.sre_sechub_automation_rules_oidc_role.name
  policy_arn = aws_iam_policy.sre_sechub_automation_rules.arn
  depends_on = [
    module.OIDC_Roles
  ]
}
