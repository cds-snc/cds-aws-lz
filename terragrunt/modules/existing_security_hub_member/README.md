## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.admin"></a> [aws.admin](#provider\_aws.admin) | n/a |
| <a name="provider_aws.member"></a> [aws.member](#provider\_aws.member) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_securityhub_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_invite_accepter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_invite_accepter) | resource |
| [aws_securityhub_member.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_member) | resource |
| [aws_caller_identity.member](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_email"></a> [email](#input\_email) | email to send invitation to | `string` | n/a | yes |

## Outputs

No outputs.
