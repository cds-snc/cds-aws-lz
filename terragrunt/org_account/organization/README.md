## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_AFT_SRC"></a> [AFT\_SRC](#module\_AFT\_SRC) | ./modules/global_controls | n/a |
| <a name="module_DISALLOW_CFN_EXTENSIONS"></a> [DISALLOW\_CFN\_EXTENSIONS](#module\_DISALLOW\_CFN\_EXTENSIONS) | ./modules/control | n/a |
| <a name="module_DumpsterFire_SRC"></a> [DumpsterFire\_SRC](#module\_DumpsterFire\_SRC) | ./modules/global_controls | n/a |
| <a name="module_Production_SRC"></a> [Production\_SRC](#module\_Production\_SRC) | ./modules/global_controls | n/a |
| <a name="module_REQUIRE_CLOUDTRAIL_LOG_FILE_VALIDATION"></a> [REQUIRE\_CLOUDTRAIL\_LOG\_FILE\_VALIDATION](#module\_REQUIRE\_CLOUDTRAIL\_LOG\_FILE\_VALIDATION) | ./modules/control | n/a |
| <a name="module_SRETools_SRC"></a> [SRETools\_SRC](#module\_SRETools\_SRC) | ./modules/global_controls | n/a |
| <a name="module_Sandbox_SRC"></a> [Sandbox\_SRC](#module\_Sandbox\_SRC) | ./modules/global_controls | n/a |
| <a name="module_Security_SRC"></a> [Security\_SRC](#module\_Security\_SRC) | ./modules/global_controls | n/a |
| <a name="module_Staging_SRC"></a> [Staging\_SRC](#module\_Staging\_SRC) | ./modules/global_controls | n/a |
| <a name="module_Test_SRC"></a> [Test\_SRC](#module\_Test\_SRC) | ./modules/global_controls | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_metric_filter.control_tower_metric_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_organizations_organization.org_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_organizational_unit.AFT](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.DumpsterFire](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.Production](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.SRETools](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.Sandbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.SandboxMigration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.Security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.Staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.Test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_policy.cds_snc_universal_guardrails](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.Sandbox-cds_snc_universal_guardrails](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_iam_policy_document.cds_snc_universal_guardrails](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
