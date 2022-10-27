module "gh_oidc_roles" {
  source = "github.com/cds-snc/terraform-modules?ref=v4.0.0//gh_oidc_role"
  roles = [
    {
      name      = local.plan_name
      repo_name = "cds-aws-lz"
      claim     = "*"
    },
    {
      name      = local.admin_name
      repo_name = "cds-aws-lz"
      claim     = "ref:refs/heads/main"
    },
    {
      name      = local.admin_plan_role
      repo_name = "cds-aws-lz"
      claim     = "*"
    },
    {
      name      = local.sre_cloud_spend
      repo_name = "cloud-spend"
      claim     = "*"
    },
    {
      name      = local.sre_sso_manage_permissions
      repo_name = "site-reliability-engineering"
      claim     = "*"
    }
  ]

  billing_tag_value = var.billing_code
}

module "attach_tf_plan_policy" {
  source            = "github.com/cds-snc/terraform-modules?ref=v3.0.2//attach_tf_plan_policy"
  account_id        = data.aws_caller_identity.current.account_id
  role_name         = local.plan_name
  bucket_name       = "${var.billing_code}-tf"
  lock_table_name   = "terraform-state-lock-dynamo"
  billing_tag_value = var.billing_code
  policy_name       = "CDSLZTFPlan"
  depends_on = [
    module.gh_oidc_roles
  ]
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
  depends_on = [
    module.gh_oidc_roles
  ]
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = local.admin_name
  policy_arn = data.aws_iam_policy.admin.arn
  depends_on = [
    module.gh_oidc_roles
  ]
}

resource "aws_iam_role_policy_attachment" "admin_plan" {
  role       = local.admin_plan_role
  policy_arn = data.aws_iam_policy.admin.arn
  depends_on = [
    module.gh_oidc_roles
  ]
}

resource "aws_iam_policy" "manage_permissions" {
  name   = "SSOManagePermissionAssignments"
  path   = "/"
  policy = data.aws_iam_policy_document.manage_permissions.json

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

data "aws_iam_policy_document" "manage_permissions" {
  statement {
    sid    = "SSOManagePermissionAssignments"
    effect = "Allow"
    actions = [
      "sso:CreateAccountAssignment",
      "sso:DescribeAccountAssignmentCreationStatus",
      "sso:DescribeAccountAssignmentDeletionStatus",
      "sso:DeleteAccountAssignment",
      "sso:ListAccountAssignment*",
      "sso:ListPermissionSets*",
    ]
    resources = [
      "arn:aws:sso:::permissionSet/${local.sso_instance_id}/*",
      "arn:aws:sso:::instance/${local.sso_instance_id}",
      "arn:aws:sso:::account/*",
    ]
  }

  statement {
    sid    = "IdentityStoreGetUser"
    effect = "Allow"
    actions = [
      "identitystore:DescribeUser",
      "identitystore:GetUserId",
      "identitystore:ListUsers",
    ]
    resources = [
      "arn:aws:identitystore:::user/*",
      "arn:aws:identitystore::${var.org_account}:identitystore/${local.sso_identity_store_id}",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "manage_permissions" {
  role       = local.sre_sso_manage_permissions
  policy_arn = aws_iam_policy.manage_permissions.arn
  depends_on = [
    module.gh_oidc_roles
  ]
}

resource "aws_iam_policy" "cloud_spend" {
  name   = "SRECloudSpendPermissionAssignments"
  path   = "/"
  policy = data.aws_iam_policy_document.cloud_spend.json

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

data "aws_iam_policy_document" "cloud_spend" {
  statement {
    effect    = "Allow"
    actions   = ["ce:GetCostAndUsage"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "organizations:ListAccounts",
      "organizations:ListTagsForResource"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "cloud_spend" {
  role       = local.sre_cloud_spend
  policy_arn = aws_iam_policy.cloud_spend.arn
  depends_on = [
    module.gh_oidc_roles
  ]
}
