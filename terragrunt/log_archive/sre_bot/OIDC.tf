locals {
  sre_vulnerability_report_oidc_role = "sre_vulnerability_report_github_action"
}

module "OIDC_Roles" {
  source      = "github.com/cds-snc/terraform-modules?ref=v5.0.0//gh_oidc_role"
  oidc_exists = true

  roles = [{
    name      = local.sre_vulnerability_report_oidc_role
    repo_name = "site-reliability-engineering"
    claim     = "ref:refs/heads/main"
  }]

  billing_tag_value = var.billing_code

  depends_on = [
    aws_iam_role.sre_vulnerability_report
  ]
}

# Allow the OIDC role to assume the SRE vulnerability report roles in log_archive and audit accounts
data "aws_iam_policy_document" "assume_sre_vulnerability_report" {
  statement {
    sid = "AssumeSREVulnerabilityReportRoles"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "arn:aws:iam::${var.account_id}:role/sre_vulnerability_report",
      "arn:aws:iam::886481071419:role/sre_vulnerability_report",
    ]
  }
}

resource "aws_iam_policy" "assume_sre_vulnerability_report" {
  name   = local.sre_vulnerability_report_oidc_role
  policy = data.aws_iam_policy_document.assume_sre_vulnerability_report.json
}

resource "aws_iam_role_policy_attachment" "attach_list_accounts_in_sandbox" {
  role       = local.sre_vulnerability_report_oidc_role
  policy_arn = aws_iam_policy.assume_sre_vulnerability_report.arn
}
