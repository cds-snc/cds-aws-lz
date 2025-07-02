#
# Athena query access
#
resource "aws_ssoadmin_permission_set" "athena_query_access" {
  name         = "Athena-Query-Access"
  description  = "Grants access to the Athena query editor and RDS connector Lambda functions."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "athena_query_access" {
  permission_set_arn = aws_ssoadmin_permission_set.athena_query_access.arn
  inline_policy      = data.aws_iam_policy_document.athena_query_access.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "athena_query_access" {
  statement {
    sid = "AthenaRead"
    actions = [
      "athena:BatchGetNamedQuery",
      "athena:BatchGetQueryExecution",
      "athena:GetDataCatalog",
      "athena:GetNamedQuery",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:GetQueryRuntimeStatistics",
      "athena:GetWorkGroup",
      "athena:ListDataCatalogs",
      "athena:ListDatabases",
      "athena:ListNamedQueries",
      "athena:ListQueryExecutions",
      "athena:ListTableMetadata",
      "athena:ListWorkGroups",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
    ]
    resources = ["*"]
  }

  statement {
    sid = "GlueRead"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTables",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AthenaS3Results"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::forms-staging-athena-bucket",
      "arn:aws:s3:::forms-staging-athena-bucket/*",
      "arn:aws:s3:::forms-production-athena-bucket",
      "arn:aws:s3:::forms-production-athena-bucket/*",
    ]
  }

  statement {
    sid = "AthenaS3ReadLogs"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::cbs-satellite-687401027353",
      "arn:aws:s3:::cbs-satellite-687401027353/*",
      "arn:aws:s3:::cbs-satellite-957818836222",
      "arn:aws:s3:::cbs-satellite-957818836222/*",
      "arn:aws:s3:::forms-staging-audit-logs-archive-storage",
      "arn:aws:s3:::forms-staging-audit-logs-archive-storage/*",
      "arn:aws:s3:::forms-production-audit-logs-archive-storage",
      "arn:aws:s3:::forms-production-audit-logs-archive-storage/*",
      "arn:aws:s3:::gc-forms-staging-athena-spill-bucket",
      "arn:aws:s3:::gc-forms-staging-athena-spill-bucket/*",
      "arn:aws:s3:::gc-forms-production-athena-spill-bucket",
      "arn:aws:s3:::gc-forms-production-athena-spill-bucket/*"
    ]
  }

  statement {
    sid = "BaseS3BucketPermissions"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
    ]
    resources = ["*"]
  }

  statement {
    sid = "DataZoneRead"
    actions = [
      "datazone:ListDomains"
    ]
    resources = ["*"]
  }

  statement {
    sid = "InvokeAthenaConnectorLambda"
    actions = [
      "lambda:InvokeFunction",
    ]
    resources = [
      "arn:aws:lambda:ca-central-1:687401027353:function:*-lambda-connector",
      "arn:aws:lambda:ca-central-1:957818836222:function:*-lambda-connector",
    ]
  }
}

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
      "rds:Describe*",
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
