#
# Dev
#
resource "aws_identitystore_group" "security_threat_modelling_dev_admin" {
  display_name      = "Security-ThreatModelling-Dev-Admin"
  description       = "Grants members administrator access to the Security Threat Modelling Dev account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "security_threat_modelling_dev_read_only" {
  display_name      = "Security-ThreatModelling-Dev-ReadOnly"
  description       = "Grants members read-only access to the Security Threat Modelling Dev account."
  identity_store_id = local.sso_identity_store_id
}


#
# Prod
#
resource "aws_identitystore_group" "security_threat_modelling_prod_admin" {
  display_name      = "Security-ThreatModelling-Prod-Admin"
  description       = "Grants members administrator access to the Security Threat Modelling Prod account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "security_threat_modelling_prod_read_only" {
  display_name      = "Security-ThreatModelling-Prod-ReadOnly"
  description       = "Grants members read-only access to the Security Threat Modelling Prod account."
  identity_store_id = local.sso_identity_store_id
}
