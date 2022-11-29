## TODO: Move this to account customization

data "aws_iam_policy_document" "ct_list_controls" {
  statement {
    effect = "Allow"
    actions = ["controltower:ListEnabledControls"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ct_list_controls" {
  name = "CDSListControlTowerControls"
  description = "List Control Tower Controls"
  policy = data.aws_iam_policy_document.ct_list_controls.json
}


resource "aws_iam_role_policy_attachment" "ct_list_controls" {
  role = local.plan_name
  policy_arn = aws_iam_policy.ct_list_controls.arn
}