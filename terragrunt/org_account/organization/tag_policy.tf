resource "aws_organizations_policy" "ssc_cbrid_tag" {
  name        = "ssc-cbrid-allowed-values"
  description = "Constrains the ssc_cbrid tag to the allowed CBR ids across the organization"
  type        = "TAG_POLICY"

  content = jsonencode({
    tags = {
      "ssc_cbrid" = {
        tag_key = {
          "@@assign" = "ssc_cbrid"
        }
        tag_value = {
          "@@assign" = ["21JC", "21MQ", "22DH", "22DI", "22DJ"]
        }
      }
    }
  })
}
