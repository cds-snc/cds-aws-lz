#
# DevOps agent: assign permissions
#

# SRE devops agent
resource "aws_ssoadmin_application_assignment" "sre_devops_agent" {
  # The Agent Space's idc_application_arn 
  application_arn = "arn:aws:sso::${var.org_account}:application/ssoins-8824c710b5ddb452/apl-88240246b5deb44b"
  principal_id    = aws_identitystore_group.sre_devops_agent.group_id
  principal_type  = "GROUP"
}

# Platform core devops agent
resource "aws_ssoadmin_application_assignment" "platform_core_devops_agent" {
  # The Agent Space's idc_application_arn 
  application_arn = "arn:aws:sso::${var.org_account}:application/ssoins-8824c710b5ddb452/apl-8824c78e21dd0415"
  principal_id    = aws_identitystore_group.platform_core_devops_agent.group_id
  principal_type  = "GROUP"
}