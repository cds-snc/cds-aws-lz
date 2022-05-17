data "aws_iam_policy_document" "this" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.account_id}:role/${var.name_of_role_to_assume}"
    ]
  }
}

resource "aws_iam_policy" "this" {
  name   = "Allow${var.name_of_role_to_assume}From${var.account_id}"
  policy = data.aws_iam_policy_document.this.json
  tags   = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = var.assume_role_name
  policy_arn = resource.aws_iam_policy.this.arn

}
