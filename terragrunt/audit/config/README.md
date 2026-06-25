## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | <= 5.84.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.84.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_compliance_report"></a> [compliance\_report](#module\_compliance\_report) | github.com/cds-snc/terraform-modules//lambda_schedule | v11.3.0 |
| <a name="module_report_bucket"></a> [report\_bucket](#module\_report\_bucket) | github.com/cds-snc/terraform-modules//S3 | v11.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_config_configuration_aggregator.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_aggregator) | resource |
| [aws_config_organization_managed_rule.require_ssc_cbrid](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_managed_rule) | resource |
| [aws_iam_role.config_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.config_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Required) The account ID to perform actions on. | `string` | n/a | yes |
| <a name="input_billing_code"></a> [billing\_code](#input\_billing\_code) | The billing code to tag our resources with | `string` | n/a | yes |
| <a name="input_config_rule_name"></a> [config\_rule\_name](#input\_config\_rule\_name) | The Config rule to inspect. | `string` | `"OrgConfigRule-require-ssc-cbrid-tag-zwgttrr2"` | no |
| <a name="input_env"></a> [env](#input\_env) | The current running environment | `string` | n/a | yes |
| <a name="input_lambda_image_tag"></a> [lambda\_image\_tag](#input\_lambda\_image\_tag) | ECR image tag the Lambda runs. Bump when you push a new image. | `string` | `"latest"` | no |
| <a name="input_org_account"></a> [org\_account](#input\_org\_account) | The account ID of the main organization account | `any` | n/a | yes |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) The name of the product you are deploying. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The current AWS region | `string` | n/a | yes |
| <a name="input_report_prefix"></a> [report\_prefix](#input\_report\_prefix) | S3 key prefix under which CSV reports are written. | `string` | `"config-compliance-reports"` | no |
| <a name="input_report_retention_days"></a> [report\_retention\_days](#input\_report\_retention\_days) | Days to retain report objects before automatic deletion. | `number` | `90` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | EventBridge schedule expression in UTC. Empty string disables scheduling. | `string` | `"cron(0 6 ? * MON *)"` | no |
| <a name="input_slack_webhook_url"></a> [slack\_webhook\_url](#input\_slack\_webhook\_url) | Incoming webhook URL for the SRE bot / Slack. | `string` | n/a | yes |
| <a name="input_top_n_accounts"></a> [top\_n\_accounts](#input\_top\_n\_accounts) | How many worst-offender accounts to list in the Slack message. | `number` | `10` | no |

## Outputs

No outputs.
