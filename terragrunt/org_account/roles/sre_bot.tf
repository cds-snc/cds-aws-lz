data "aws_iam_policy_document" "sre_bot_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::283582579564:role/sre-bot-ecs-role",
        var.admin_sso_role_arn
      ]
    }
  }
}

resource "aws_iam_role" "sre_bot" {
  name               = "sre_bot_role"
  assume_role_policy = sensitive(data.aws_iam_policy_document.sre_bot_role.json)

  tags = local.common_tags
}

data "aws_iam_policy_document" "sre_bot_policy" {
  version = "2012-10-17"

  statement {
    sid    = "ReadOrgAccounts"
    effect = "Allow"
    actions = [
      "organizations:ListAccounts",
      "organizations:DescribeAccount",
      "organizations:ListTagsForResource",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ReadCostExplorer"
    effect = "Allow"
    actions = [
      "ce:GetCostAndUsage"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageIdentityStoreUsers"
    effect = "Allow"
    actions = [
      "identitystore:GetUserId",
      "identitystore:CreateUser",
      "identitystore:DescribeUser",
      "identitystore:ListUsers",
      "identitystore:DeleteUser",
      "identitystore:UpdateUser",
      "identitystore:ListGroups",
      "identitystore:ListGroupMembershipsForMember",
      "identitystore:ListGroupMemberships",
      "identitystore:DescribeGroup",
      "identitystore:DescribeGroupMembership",
      "identitystore:GetGroupId",
      "identitystore:IsMemberInGroups",
      "identitystore:GetGroupMembershipId",
      "identitystore:CreateGroupMembership",
      "identitystore:DeleteGroupMembership"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageSSOAssignments"
    effect = "Allow"
    actions = [
      "sso:ListAccountAssignmentsForPrincipal",
      "sso:CreateAccountAssignment",
      "sso:ListPermissionSets"
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
