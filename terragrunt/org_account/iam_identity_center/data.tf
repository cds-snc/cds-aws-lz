#
# AWS default permission sets
#
data "aws_ssoadmin_permission_set" "aws_administrator_access" {
  instance_arn = local.sso_instance_arn
  name         = "AWSAdministratorAccess"
}

data "aws_ssoadmin_permission_set" "aws_read_only_access" {
  instance_arn = local.sso_instance_arn
  name         = "AWSReadOnlyAccess"
}
