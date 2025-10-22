data "aws_iam_policy_document" "scp_deny_ec2_connect" {
  statement {
    effect = "Deny"
    actions = [
      "ec2:CreateKeyPair",
      "ec2-instance-connect:OpenTunnel",
      "ec2-instance-connect:SendSSHPublicKey",
      "ec2-instance-connect:SendSerialConsoleSSHPublicKey"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Deny"
    actions = [
      "ssm:StartSession"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ssm:*:*:managed-instance/*"
    ]
  }
}

resource "aws_organizations_policy" "scp_deny_ec2_connect" {
  name        = "Deny EC2 Instance Connect"
  description = "Deny EC2 Instance Connect actions across the organization"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp_deny_ec2_connect.json
}
