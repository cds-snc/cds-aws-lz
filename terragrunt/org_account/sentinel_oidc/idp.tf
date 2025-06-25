locals {
  azure_tenant_id            = "221ca1d3-b3f2-4346-8abc-88f802495c7d"
  azure_client_id            = "c8b9cf86-e2b4-4428-b356-14313412a4d1"
  azure_client_id_cds_snc_la = "50a00e76-8dcf-4c54-b8b1-94f67e340960"
  url                        = "sts.windows.net/${local.azure_tenant_id}/"
  url_https                  = "https://${local.url}"
}

data "tls_certificate" "thumprint" {
  url = local.url_https
}

# aws_iam_openid_connect_provider.azure:
resource "aws_iam_openid_connect_provider" "azure" {
  client_id_list = sort([
    local.azure_client_id,
    local.azure_client_id_cds_snc_la,
  ])
  thumbprint_list = [
    data.tls_certificate.thumprint.certificates.0.sha1_fingerprint,
  ]
  url = local.url_https
}
