#
# DevOps agent: assign permissions
#

resource "aws_ssoadmin_application_assignment" "sre_devops_agent" {
  application_arn = var.application_arn # TBD The Agent Space's idc_application_arn
  principal_id    = aws_identitystore_group.sre_devops_agent.group_id
  principal_type  = "GROUP"
}