## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aft_slack_notification"></a> [aft\_slack\_notification](#module\_aft\_slack\_notification) | github.com/cds-snc/terraform-modules//notify_slack | v9.3.9 |
| <a name="module_assume_apply_role"></a> [assume\_apply\_role](#module\_assume\_apply\_role) | ../../modules/assume_role | n/a |
| <a name="module_assume_plan_role"></a> [assume\_plan\_role](#module\_assume\_plan\_role) | ../../modules/assume_role | n/a |
| <a name="module_attach_tf_plan_policy_assume"></a> [attach\_tf\_plan\_policy\_assume](#module\_attach\_tf\_plan\_policy\_assume) | github.com/cds-snc/terraform-modules//attach_tf_plan_policy | v3.0.2 |
| <a name="module_gh_oidc_roles"></a> [gh\_oidc\_roles](#module\_gh\_oidc\_roles) | github.com/cds-snc/terraform-modules//gh_oidc_role | v9.0.3 |
| <a name="module_password_policy"></a> [password\_policy](#module\_password\_policy) | github.com/cds-snc/terraform-modules//aws_goc_password_policy | v3.0.2 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.aft_vault_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.assume_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.assume_aft_vault_cleanup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.aft_vault_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_sns_topic.aft_failure_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |
| [aws_sns_topic.aft_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aft_slack_webhook"></a> [aft\_slack\_webhook](#input\_aft\_slack\_webhook) | The slack webhook URL to be used by Account Factory for Terraform | `any` | n/a | yes |

## Outputs

No outputs.
