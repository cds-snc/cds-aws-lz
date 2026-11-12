## TODO: Move this to account customization

data "aws_iam_policy_document" "ct_list_controls" {
  statement {
    effect = "Allow"
    # AWS provider 6 reads aws_controltower_control with GetEnabledControl; the
    # 4.67 provider that org_account/organization is locked to today only needs
    # ListEnabledControls. Keep both while the provider upgrade is in progress.
    actions = [
      "controltower:GetEnabledControl",
      "controltower:ListEnabledControls",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ct_list_controls" {
  name        = "CDSListControlTowerControls"
  description = "List Control Tower Controls"
  policy      = data.aws_iam_policy_document.ct_list_controls.json
}


resource "aws_iam_role_policy_attachment" "ct_list_controls" {
  role       = local.plan_name
  policy_arn = aws_iam_policy.ct_list_controls.arn
}