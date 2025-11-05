data "aws_iam_policy_document" "scp_deny_ec2_run" {
  statement {
    effect = "Deny"
    actions = [
      "ec2:RunInstances"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_organizations_policy" "scp_deny_ec2_run" {
  name        = "Deny EC2 Instance Run"
  description = "Deny EC2 Instance Run actions across targeted OUs and accounts"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp_deny_ec2_run.json
}
