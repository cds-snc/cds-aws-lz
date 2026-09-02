#
# Athena query access
#
resource "aws_ssoadmin_permission_set" "platform_unified_accounts_athena_query_access" {
  name         = "Platform-Unified-Accounts-Athena-Query-Access"
  description  = "Grants access to the Athena query editor."
  instance_arn = local.sso_instance_arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "platform_unified_accounts_athena_query_access" {
  permission_set_arn = aws_ssoadmin_permission_set.platform_unified_accounts_athena_query_access.arn
  inline_policy      = data.aws_iam_policy_document.platform_unified_accounts_athena_query_access.json
  instance_arn       = local.sso_instance_arn
}

data "aws_iam_policy_document" "platform_unified_accounts_athena_query_access" {
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
      "arn:aws:s3:::unified-accounts-staging-athena",
      "arn:aws:s3:::unified-accounts-staging-athena/*",
      "arn:aws:s3:::unified-accounts-production-athena",
      "arn:aws:s3:::unified-accounts-production-athena/*",
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
      "arn:aws:s3:::cbs-satellite-915144821201",
      "arn:aws:s3:::cbs-satellite-915144821201/*",
      "arn:aws:s3:::cbs-satellite-778127141858",
      "arn:aws:s3:::cbs-satellite-778127141858/*",
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
}
