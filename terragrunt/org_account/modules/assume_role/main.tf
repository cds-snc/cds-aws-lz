resource "aws_iam_role" "this" {
  name               = "${var.assume_account_id}_${var.role_suffix}"
  tags               = local.common_tags
  assume_role_policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    sid     = "AssumePlanRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.assume_account_id}:${var.role_name_to_assume}"]
    }
  }
}

