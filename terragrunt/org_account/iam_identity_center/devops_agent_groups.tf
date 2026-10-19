#
# SRE Team groups 
#
resource "aws_identitystore_group" "sre_devops_agent" {
  display_name      = "SRE-DevOps-Agent"
  description       = "Grants members access to the SRE AWS Devops Agent space."
  identity_store_id = local.sso_identity_store_id
}

#
# Platform core groups 
#
resource "aws_identitystore_group" "platform_core_devops_agent" {
  display_name      = "PlatformCore-DevOps-Agent"
  description       = "Grants members access to the Plaform Core AWS Devops Agent space."
  identity_store_id = local.sso_identity_store_id
}

#
# CanadaLogin groups 
#
resource "aws_identitystore_group" "canada_login_devops_agent" {
  display_name      = "CanadaLogin-DevOps-Agent"
  description       = "Grants members access to the CanadaLogin AWS Devops Agent space."
  identity_store_id = local.sso_identity_store_id
}