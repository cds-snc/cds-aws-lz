## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_aws.log_archive"></a> [aws.log\_archive](#provider\_aws.log\_archive) | n/a |
| <a name="provider_aws.log_archive_us_east_1"></a> [aws.log\_archive\_us\_east\_1](#provider\_aws.log\_archive\_us\_east\_1) | n/a |
| <a name="provider_aws.log_archive_us_west_2"></a> [aws.log\_archive\_us\_west\_2](#provider\_aws.log\_archive\_us\_west\_2) | n/a |
| <a name="provider_aws.us-east-1"></a> [aws.us-east-1](#provider\_aws.us-east-1) | n/a |
| <a name="provider_aws.us-west-2"></a> [aws.us-west-2](#provider\_aws.us-west-2) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_AFT_management_apply"></a> [AFT\_management\_apply](#module\_AFT\_management\_apply) | ../../modules/allow_assumed_role | n/a |
| <a name="module_AFT_management_plan"></a> [AFT\_management\_plan](#module\_AFT\_management\_plan) | ../../modules/allow_assumed_role | n/a |
| <a name="module_aft_managment"></a> [aft\_managment](#module\_aft\_managment) | ../../modules/existing_security_hub_member | n/a |
| <a name="module_alarm_actions"></a> [alarm\_actions](#module\_alarm\_actions) | github.com/cds-snc/terraform-modules//user_login_alarm | v3.0.2 |
| <a name="module_audit"></a> [audit](#module\_audit) | ../../modules/existing_security_hub_member | n/a |
| <a name="module_audit_apply"></a> [audit\_apply](#module\_audit\_apply) | ../../modules/allow_assumed_role | n/a |
| <a name="module_audit_plan"></a> [audit\_plan](#module\_audit\_plan) | ../../modules/allow_assumed_role | n/a |
| <a name="module_gd_aft_management_detector"></a> [gd\_aft\_management\_detector](#module\_gd\_aft\_management\_detector) | ../../modules/guardduty_detectors | n/a |
| <a name="module_gd_audit_detector"></a> [gd\_audit\_detector](#module\_gd\_audit\_detector) | ../../modules/guardduty_detectors | n/a |
| <a name="module_gd_log_archive_detector"></a> [gd\_log\_archive\_detector](#module\_gd\_log\_archive\_detector) | ../../modules/guardduty_detectors | n/a |
| <a name="module_gd_org_detector"></a> [gd\_org\_detector](#module\_gd\_org\_detector) | ../../modules/guardduty_detectors | n/a |
| <a name="module_gh_oidc_roles"></a> [gh\_oidc\_roles](#module\_gh\_oidc\_roles) | github.com/cds-snc/terraform-modules//gh_oidc_role | v4.0.0 |
| <a name="module_guardduty_forwarder"></a> [guardduty\_forwarder](#module\_guardduty\_forwarder) | github.com/cds-snc/terraform-modules//sentinel_forwarder | v9.3.8 |
| <a name="module_log_archive_apply"></a> [log\_archive\_apply](#module\_log\_archive\_apply) | ../../modules/allow_assumed_role | n/a |
| <a name="module_log_archive_plan"></a> [log\_archive\_plan](#module\_log\_archive\_plan) | ../../modules/allow_assumed_role | n/a |
| <a name="module_org"></a> [org](#module\_org) | ../../modules/existing_security_hub_member | n/a |
| <a name="module_password_policy"></a> [password\_policy](#module\_password\_policy) | github.com/cds-snc/terraform-modules//aws_goc_password_policy | v3.0.2 |
| <a name="module_publishing_bucket"></a> [publishing\_bucket](#module\_publishing\_bucket) | github.com/cds-snc/terraform-modules//S3 | v3.0.2 |
| <a name="module_publishing_log_bucket"></a> [publishing\_log\_bucket](#module\_publishing\_log\_bucket) | github.com/cds-snc/terraform-modules//S3_log_bucket | v3.0.2 |
| <a name="module_securityhub_forwarder"></a> [securityhub\_forwarder](#module\_securityhub\_forwarder) | github.com/cds-snc/terraform-modules//sentinel_forwarder | v9.3.8 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.cds_sentinel_securityhub_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_guardduty_organization_admin_account.gd_admin_ca_central_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_guardduty_organization_admin_account.gd_admin_us_east_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_guardduty_organization_admin_account.gd_admin_us_west_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_guardduty_organization_configuration.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_guardduty_organization_configuration.config_us_east_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_guardduty_organization_configuration.config_us_west_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration) | resource |
| [aws_guardduty_publishing_destination.pub_dest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_publishing_destination) | resource |
| [aws_guardduty_publishing_destination.pub_dest_us_east_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_publishing_destination) | resource |
| [aws_guardduty_publishing_destination.pub_dest_us_west_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_publishing_destination) | resource |
| [aws_iam_policy.cloud_spend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ct_list_controls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.manage_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.azure_sentinel](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.admin_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloud_spend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ct_list_controls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.manage_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.cds_sentinel_guard_duty_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cds_sentinel_guard_duty_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket_notification.azure_cloudtrail_bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.cds_sentinel_guard_duty_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_securityhub_account.log_archive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_finding_aggregator.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_organization_admin_account.admin_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |
| [aws_securityhub_organization_configuration.sh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |
| [aws_securityhub_standards_subscription.cis_aws_foundations_benchmark](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription) | resource |
| [aws_servicecatalog_principal_portfolio_association.aft_role_account_factory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/servicecatalog_principal_portfolio_association) | resource |
| [aws_sns_topic.critical](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.warning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sqs_queue.cloudtrail_sqs_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.sqs_queue_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.log_archive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.azure_sentinel_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cds_sentinel_guard_duty_logs_kms_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cds_sentinel_guard_duty_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloud_spend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ct_list_controls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.manage_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.aft_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_servicecatalog_portfolio.account_factory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/servicecatalog_portfolio) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assume_role_name"></a> [assume\_role\_name](#input\_assume\_role\_name) | The name of the role to assume | `string` | n/a | yes |
| <a name="input_lw_customer_id"></a> [lw\_customer\_id](#input\_lw\_customer\_id) | The log workspace customer id for the sentinel forwarder | `string` | n/a | yes |
| <a name="input_lw_customer_ids"></a> [lw\_customer\_ids](#input\_lw\_customer\_id) | Allows multiple log workspace customer ids to be passed to the Azure Sentinel role. | `list(string)` | n/a | yes |
| <a name="input_lw_shared_key"></a> [lw\_shared\_key](#input\_lw\_shared\_key) | The log workspace shared key for the sentinel forwarder | `string` | n/a | yes |

## Outputs

No outputs.
