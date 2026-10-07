#
# DevOps agent: assign permissions
#

resource "aws_ssoadmin_application_assignment" "sre_devops_agent" {
  application_arn =   application_arn = "arn:aws:sso::${var.org_account}:application/ssoins-8824c710b5ddb452/apl-88240246b5deb44b" # The Agent Space's idc_application_arn
  principal_id    = aws_identitystore_group.sre_devops_agent.group_id
  principal_type  = "GROUP"
}