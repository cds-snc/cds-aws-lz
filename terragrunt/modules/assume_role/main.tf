
resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.this.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}


data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${var.org_account}:role/${var.org_account_role_name}",
        "arn:aws:iam::${var.org_account}:user/CalvinRodo"] # Will only be here as long as I need to debug TF locally.
    }
  }
}
