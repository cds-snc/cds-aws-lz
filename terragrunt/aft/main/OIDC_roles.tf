locals {
  aft_vault_cleanup = "aft-vault-cleanup-resources"
}

module "gh_oidc_roles" {
  source      = "github.com/cds-snc/terraform-modules//gh_oidc_role?ref=v9.4.11"
  oidc_exists = true

  roles = [
    {
      name      = local.aft_vault_cleanup
      repo_name = "site-reliability-engineering"
      claim     = "ref:refs/heads/main"
    }
  ]

  billing_tag_value = var.billing_code
}

data "aws_iam_policy_document" "aft_vault_cleanup" {
  statement {
    sid    = "AllowDeleteRecoveryPoints"
    effect = "Allow"
    actions = [
      "backup:DeleteRecoveryPoint",
      "backup:ListRecoveryPointsByBackupVault"
    ]
    resources = [
      "arn:aws:backup:${var.region}:${var.account_id}:backup-vault:aft-controltower-backup-vault",
      "arn:aws:backup:${var.region}:${var.account_id}:recovery-point:*"
    ]
  }

  statement {
    sid    = "AllowToggleConfigRecorder"
    effect = "Allow"
    actions = [
      "config:DescribeConfigurationRecorders",
      "config:StopConfigurationRecorder",
      "config:StartConfigurationRecorder",
      "config:DescribeConfigurationRecorderStatus"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "aft_vault_cleanup" {
  name        = "aft-vault-cleanup-policy"
  description = "Policy to allow the aft vault cleanup script to run"
  policy      = data.aws_iam_policy_document.aft_vault_cleanup.json

}
resource "aws_iam_role_policy_attachment" "assume_aft_vault_cleanup_role" {
  role       = local.aft_vault_cleanup
  policy_arn = aws_iam_policy.aft_vault_cleanup.arn
  depends_on = [
    module.gh_oidc_roles
  ]
}
