resource "aws_iam_role" "this" {
  name = "${var.assume_account_id}_${var.role_suffix}"
  tags = local.common_tags
}

data "aws_iam_policy_document" "this" {
  statement {
    sid     = "AssumePlanRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.assume_account_id}:${var.apply_role_name_to_assume}"]
    }
  }
}

resource "aws_iam_policy" "this" {
  name   = "${var.assume_account_id}-apply"
  path   = "/"
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = data.aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}
