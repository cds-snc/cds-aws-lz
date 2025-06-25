# Assume role policy for the central cbs account to manage config rules via Terraform
resource "aws_iam_role" "config_terraform_role" {
  name               = "ConfigTerraformAdminExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.config_execution_role.json
}

data "aws_iam_policy_document" "config_execution_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.cbs_central_account_id}:role/ConfigTerraformAdministratorRole"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values = [
        "CBSGitHubActions",
      ]
    }
  }
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "config_tf_admin" {
  role       = aws_iam_role.config_terraform_role.name
  policy_arn = data.aws_iam_policy.admin.arn
}

#
# Role used by satellite account S3 buckets to replicate objects to
# the CbsCentral log archive S3 bucket.
#
resource "aws_iam_role" "s3_replicate" {
  name               = "CbsSatelliteReplicateToLogArchive"
  assume_role_policy = data.aws_iam_policy_document.s3_replicate_assume.json
}

data "aws_iam_policy_document" "s3_replicate_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
