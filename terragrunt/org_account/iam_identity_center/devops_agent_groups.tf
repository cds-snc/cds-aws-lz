#
# SRE Team groups 
#
resource "aws_identitystore_group" "sre_devops_agent" {
  display_name      = "SRE-DevOps-Agent"
  description       = "Grants members access to the SRE AWS Devops Agent space."
  identity_store_id = local.sso_identity_store_id
}