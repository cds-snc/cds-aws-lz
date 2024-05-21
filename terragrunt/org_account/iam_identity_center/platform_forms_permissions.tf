#
# RDS query editor access
#
resource "aws_ssoadmin_permission_set" "rds_query_access" {
  name         = "RDS-Query-Access"
  description  = "Grants access to the RDS query editor and Secrets used for authentication."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "rds_query_access" {
  permission_set_arn = aws_ssoadmin_permission_set.rds_query_access.arn
  inline_policy      = data.aws_iam_policy_document.rds_query_access.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "rds_query_access" {

  statement {
    sid    = "SecretsDatabaseCredentialsWrite"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutResourcePolicy",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:TagResource"
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:rds-db-credentials/*",
    ]
  }

  statement {
    sid    = "SecretsDatabaseCredentialsRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:database-secret-*"
    ]
  }

  statement {
    sid    = "RDSQueryEditorAccess"
    effect = "Allow"
    actions = [
      "dbqms:CreateFavoriteQuery",
      "dbqms:CreateQueryHistory",
      "dbqms:DeleteFavoriteQueries",
      "dbqms:DeleteQueryHistory",
      "dbqms:DescribeFavoriteQueries",
      "dbqms:DescribeQueryHistory",
      "dbqms:GetQueryString",
      "dbqms:UpdateFavoriteQuery",
      "dbqms:UpdateQueryHistory",
      "rds-data:BatchExecuteStatement",
      "rds-data:BeginTransaction",
      "rds-data:CommitTransaction",
      "rds-data:ExecuteStatement",
      "rds-data:RollbackTransaction",
      "secretsmanager:CreateSecret",
      "secretsmanager:GetRandomPassword",
      "secretsmanager:ListSecrets",
      "tag:GetResources",
    ]
    resources = ["*"]
  }
}
