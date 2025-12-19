#
# Production 
#
resource "aws_identitystore_group" "gc_signin_production_admin" {
  display_name      = "GCSignIn-Production-Admin"
  description       = "Grants members administrator access to the GC Signin Production account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_production_read_only" {
  display_name      = "GCSignIn-Production-ReadOnly"
  description       = "Grants members read-only access to the GC Signin Production account."
  identity_store_id = local.sso_identity_store_id
}

resource "aws_identitystore_group" "gc_signin_production_read_only_billing" {
  display_name      = "GCSignIn-Production-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the GC Signin Production account."
  identity_store_id = local.sso_identity_store_id
}

#
# Staging
#
resource "aws_identitystore_group" "gc_signin_staging_admin" {
  display_name      = "GCSignIn-Staging-Admin"
  description       = "Grants members administrator access to the GC Signin Staging account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_staging_read_only" {
  display_name      = "GCSignIn-Staging-ReadOnly"
  description       = "Grants members read-only access to the GC Signin Staging account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_staging_read_only_billing" {
  display_name      = "GCSignIn-Staging-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the GC Signin Staging account."
  identity_store_id = local.sso_identity_store_id
}

# 
# Dev 
#
resource "aws_identitystore_group" "gc_signin_dev_admin" {
  display_name      = "GCSignIn-Dev-Admin"
  description       = "Grants members administrator access to the GC Signin Dev account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_dev_read_only" {
  display_name      = "GCSignIn-Dev-ReadOnly"
  description       = "Grants members read-only access to the GC Signin Dev account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_dev_read_only_billing" {
  display_name      = "GCSignIn-Dev-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the GC Signin Dev account."
  identity_store_id = local.sso_identity_store_id
}

# 
# Dev2
#
resource "aws_identitystore_group" "gc_signin_dev2_admin" {
  display_name      = "GCSignIn-Dev2-Admin"
  description       = "Grants members administrator access to the GC Signin Dev2 account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_dev2_read_only" {
  display_name      = "GCSignIn-Dev2-ReadOnly"
  description       = "Grants members read-only access to the GC Signin Dev2 account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_dev2_read_only_billing" {
  display_name      = "GCSignIn-Dev2-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the GC Signin Dev2 account."
  identity_store_id = local.sso_identity_store_id
}

# 
# Test 
#
resource "aws_identitystore_group" "gc_signin_test_admin" {
  display_name      = "GCSignIn-Test-Admin"
  description       = "Grants members administrator access to the GC Signin Test account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_test_read_only" {
  display_name      = "GCSignIn-Test-ReadOnly"
  description       = "Grants members read-only access to the GC Signin Test account."
  identity_store_id = local.sso_identity_store_id
}
resource "aws_identitystore_group" "gc_signin_test_read_only_billing" {
  display_name      = "GCSignIn-Test-Billing-ReadOnly"
  description       = "Grants members read-only Billing and Cost Explorer access to the GC Signin Test account."
  identity_store_id = local.sso_identity_store_id
}