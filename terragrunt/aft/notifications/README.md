## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aft_failure_notifications"></a> [aft\_failure\_notifications](#module\_aft\_failure\_notifications) | github.com/cds-snc/terraform-modules//notify_slack | v9.3.9 |

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic_subscription.aft_failure_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic.aft_failure_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aft_notifications_hook"></a> [aft\_notifications\_hook](#input\_aft\_notifications\_hook) | (Required) The webhook to post AFT Notifications to | `string` | n/a | yes |

## Outputs

No outputs.
