data "aws_iam_policy_document" "sre_bot_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::283582579564:role/sre-bot-ecs-role",
        "arn:aws:iam::${var.org_account}:role/AWSReservedSSO_AWSAdministratorAccess_*"
      ]
    }
  }
}

resource "aws_iam_role" "sre_bot" {
  name               = "sre_bot_role"
  assume_role_policy = data.aws_iam_policy_document.sre_bot_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "sre_bot_policy" {
  version = "2012-10-17"

  statement {
    sid       = "ReadOrgAccounts"
    effect    = "Allow"
    actions   = ["organizations:ListAccounts"]
    resources = ["*"]
  }

  statement {
    sid    = "ReadTrustedAdvisor"
    effect = "Allow"
    actions = [
      "trustedadvisor:DescribeAccount",
      "trustedadvisor:DescribeChecks",
      "trustedadvisor:DescribeCheckSummaries",
      "trustedadvisor:DescribeAccountAccess",
      "trustedadvisor:DescribeOrganization",
      "trustedadvisor:DescribeReports",
      "trustedadvisor:DescribeServiceMetadata",
      "trustedadvisor:DescribeOrganizationAccounts",
      "trustedadvisor:ListAccountsForParent",
      "trustedadvisor:ListRoots",
      "trustedadvisor:ListOrganizationalUnitsForParent"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sre_bot_policy" {
  name   = "sre_bot_policy"
  policy = data.aws_iam_policy_document.sre_bot_policy.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "sre_bot" {
  role       = aws_iam_role.sre_bot.name
  policy_arn = aws_iam_policy.sre_bot_policy.arn
}
