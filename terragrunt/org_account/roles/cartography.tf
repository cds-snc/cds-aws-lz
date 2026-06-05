locals {
  cartography_account_id = "794722365809"
}

resource "aws_iam_role" "cartography_org_list" {
  name = "secopsAssetInventoryOrgAccountListRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${local.cartography_account_id}:role/secopsAssetInventoryCartographyRole" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cartography_org_list_security_audit" {
  role       = aws_iam_role.cartography_org_list.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

data "aws_iam_policy_document" "cartography_org_list" {
  statement {
    effect = "Allow"
    actions = [
      "organizations:DescribeOrganization",
      "organizations:ListAccounts",
      "organizations:ListRoots",
      "organizations:ListAccountsForParent",
      "organizations:ListOrganizationalUnitsForParent",
      "organizations:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cartography_org_list" {
  name   = "CartographyOrgList"
  role   = aws_iam_role.cartography_org_list.id
  policy = data.aws_iam_policy_document.cartography_org_list.json
}