## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | <= 5.84.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.84.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_config_configuration_aggregator.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_aggregator) | resource |
| [aws_config_organization_managed_rule.require_ssc_cbrid](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_managed_rule) | resource |
| [aws_iam_role.config_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.config_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Required) The account ID to perform actions on. | `string` | n/a | yes |
| <a name="input_billing_code"></a> [billing\_code](#input\_billing\_code) | The billing code to tag our resources with | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | The current running environment | `string` | n/a | yes |
| <a name="input_org_account"></a> [org\_account](#input\_org\_account) | The account ID of the main organization account | `any` | n/a | yes |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) The name of the product you are deploying. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The current AWS region | `string` | n/a | yes |

## Outputs

No outputs.
