data "aws_iam_policy_document" "scp_deny_ec2_connect" {
  statement {
    effect = "Deny"
    actions = [
      "ec2:CreateKeyPair",
      "ec2:DescribeInstances",
      "ec2-instance-connect:OpenTunnel",
      "ec2-instance-connect:SendSSHPublicKey",
      "ec2-instance-connect:SendSerialConsoleSSHPublicKey"
    ]
    resources = [
      "*"
    ]
  }
}


resource "aws_organizations_policy" "scp_deny_ec2_connect" {
  name        = "Deny EC2 Instance Connect"
  description = "Deny EC2 Instance Connect actions across the organization"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp_deny_ec2_connect.json
}
