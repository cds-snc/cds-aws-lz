# aws_iam_role.sentinel_oidc:

resource "aws_iam_role" "sentinel_oidc" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${local.url}:aud" = local.azure_client_id
            }
          }
          Effect = "Allow"
          Principal = {
            Federated = aws_iam_openid_connect_provider.azure.arn
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description = "for sentinel function apps"
  name        = "Sentinel-OIDC-Organizations-ReadOnly"
}

resource "aws_iam_role_policy_attachment" "sentinel_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSOrganizationsReadOnlyAccess"
  role       = aws_iam_role.sentinel_oidc.name
}
