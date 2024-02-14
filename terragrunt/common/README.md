## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.40.0, <= 5.11 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

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
