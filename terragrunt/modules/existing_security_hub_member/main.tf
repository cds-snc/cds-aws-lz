
# Enable Security Hub
resource "aws_securityhub_account" "this" {
  provider = aws.member

  auto_enable_controls = true
}

data "aws_caller_identity" "member" {
  provider = aws.member
}

# Add the account as a delegated member of security hub
resource "aws_securityhub_member" "this" {
  provider = aws.admin

  account_id = data.aws_caller_identity.member.account_id

  email  = var.email
  invite = true

  depends_on = [aws_securityhub_account.this]

  lifecycle { # Known bug https://github.com/hashicorp/terraform-provider-aws/issues/24320
    ignore_changes = [email]
  }
}

# Accept the invitiation
resource "aws_securityhub_invite_accepter" "this" {
  provider   = aws.member
  master_id  = aws_securityhub_member.this.master_id
  depends_on = [aws_securityhub_member.this]
}
