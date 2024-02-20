## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assume_policy_name"></a> [assume\_policy\_name](#input\_assume\_policy\_name) | (Required) The name of the policy | `string` | n/a | yes |
| <a name="input_billing_tag_key"></a> [billing\_tag\_key](#input\_billing\_tag\_key) | The key of the tag to be used for billing purposes | `string` | `"CostCentre"` | no |
| <a name="input_billing_tag_value"></a> [billing\_tag\_value](#input\_billing\_tag\_value) | The value of the tag to be used for billing purposes | `string` | n/a | yes |
| <a name="input_extra_roles"></a> [extra\_roles](#input\_extra\_roles) | A list of extra roles that can assume this role | `list(string)` | `[]` | no |
| <a name="input_org_account"></a> [org\_account](#input\_org\_account) | (Required) The account number of the organization allowed to assume the role | `string` | n/a | yes |
| <a name="input_org_account_role_name"></a> [org\_account\_role\_name](#input\_org\_account\_role\_name) | (Required) The name of the role allowed to assume this role | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | (Required) The name of the role allowed to assume this role | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | n/a |
