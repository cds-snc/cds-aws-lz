data "aws_organizations_organization" "org" {}

resource "aws_organizations_organizational_unit" "production" {
  name      = "production"
  parent_id = data.aws_organizations_organization.org.roots.0.id
}