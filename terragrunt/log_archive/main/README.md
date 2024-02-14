## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_assume_apply_role"></a> [assume\_apply\_role](#module\_assume\_apply\_role) | ../../modules/assume_role | n/a |
| <a name="module_assume_plan_role"></a> [assume\_plan\_role](#module\_assume\_plan\_role) | ../../modules/assume_role | n/a |
| <a name="module_attach_tf_plan_policy_assume"></a> [attach\_tf\_plan\_policy\_assume](#module\_attach\_tf\_plan\_policy\_assume) | github.com/cds-snc/terraform-modules//attach_tf_plan_policy | v3.0.2 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role_policy_attachment.assume_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
