# Aggregate AWS Config data from all accounts and regions in the organization
resource "aws_config_configuration_aggregator" "organization" {
  name = "cds-cbr-tags-aggregator"

  organization_aggregation_source {
    regions  = ["ca-central-1", "us-east-1"]
    role_arn = aws_iam_role.config_aggregator.arn
  }
}

# IAM role assumed by AWS Config to collect data across the organization
resource "aws_iam_role" "config_aggregator" {
  name = "AWSConfigRoleForOrganizations"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach the AWS managed policy for organization-wide Config access
resource "aws_iam_role_policy_attachment" "config_aggregator" {
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_organization_custom_policy_rule" "ssc_cbrid" {
  name           = "require-ssc-cbrid-tag"
  policy_runtime = "guard-2.x.x"
  policy_text    = <<-EOF
#
# require-ssc-cbrid-tag
#
# Enforces the ssc_cbrid tag across the organization:
#   core types   -> ssc_cbrid must == "22DH"
#   workload     -> ssc_cbrid must be one of [22DI, 21JC, 22DJ]
#   untaggable / excluded types -> not evaluated (NOT_APPLICABLE)

# Core infrastructure: must carry the account-level cbrid (22DH).
let core_types = [
  "AWS::IAM::Group","AWS::IAM::ManagedPolicy","AWS::IAM::Role","AWS::IAM::User","AWS::IAM::InstanceProfile",
  "AWS::Cognito::UserPool","AWS::Cognito::IdentityPool",
  "AWS::EC2::VPC","AWS::EC2::Subnet","AWS::EC2::SecurityGroup","AWS::EC2::RouteTable",
  "AWS::EC2::InternetGateway","AWS::EC2::NatGateway","AWS::EC2::VPCEndpoint",
  "AWS::EC2::CustomerGateway","AWS::EC2::VPNConnection","AWS::EC2::VPNGateway",
  "AWS::ElasticLoadBalancing::LoadBalancer","AWS::ElasticLoadBalancingV2::LoadBalancer",
  "AWS::ElasticLoadBalancingV2::TargetGroup",
  "AWS::WAFv2::WebACL","AWS::Shield::Protection",
  "AWS::GuardDuty::Detector",
  "AWS::KMS::Key","AWS::SecretsManager::Secret",
  "AWS::CloudWatch::Alarm","AWS::Logs::LogGroup",
  "AWS::CloudFormation::Stack","AWS::CloudFormation::StackSet",
  "AWS::S3::Bucket","AWS::EC2::Volume","AWS::EC2::Snapshot",
  "AWS::SSM::Document","AWS::SSM::Parameter",
  "AWS::CodePipeline::Pipeline","AWS::CodeBuild::Project",
  "AWS::SQS::Queue","AWS::SNS::Topic",
  "AWS::StepFunctions::StateMachine","AWS::StepFunctions::Activity"
]

# Types that have no standalone tags (e.g. inline IAM policies, aliases,
# sub-resources). Evaluating these would be a guaranteed false NON_COMPLIANT.
let untaggable_types = [
  "AWS::ElasticLoadBalancingV2::Listener",
  "AWS::ElasticLoadBalancingV2::ListenerRule",
  "AWS::KMS::Alias",
  "AWS::CloudWatch::Dashboard",
  "AWS::SNS::Subscription",
  "AWS::Config::ResourceCompliance",
  "AWS::Config::ConformancePackCompliance",
  "AWS::IAM::Policy"   # inline policy - not a taggable resource
]

# Types deliberately out of scope: noisy, platform-managed, or tagged by
# another process (e.g. org-enabled Security Hub, StackSet-deployed tooling).
let excluded_types = [
  "AWS::EC2::NetworkInterface",
  "AWS::Cassandra::Keyspace",
  "AWS::CodeDeploy::DeploymentConfig",
  "AWS::IoT::DomainConfiguration",
  "AWS::SecurityHub::Hub",
  "AWS::SecurityHub::Standard",
  "AWS::Scheduler::ScheduleGroup",
  "AWS::ServiceDiscovery",
  "AWS::ResourceExplorer2"
]

# Allowed cbrid values for non-core (workload) resources.
let workload_allowed = ["22DI","21JC","22DJ"]

#
# Rule 1: CORE -> ssc_cbrid must be 22DH
#
# Why this structure (do not "simplify"):
#  - `when tags exists` is the OUTER gate. It is the only construct that skips
#    cleanly (no retrieval error) when the tags key is entirely absent.
#  - `tags is_struct or tags is_list` catches tags that are present but the
#    wrong type (scalar/null) so they fail instead of vacuously passing.
#  - The value checks live INSIDE `when tags is_struct` / `when tags is_list`.
#    Guard does NOT short-circuit, so an ungated key filter would still run on a
#    non-map and throw a retrieval error - gating is what prevents that.
#  - Use the keys/key FILTER form, not dotted `tags.ssc_cbrid`: a missing key in
#    a dotted query throws a retrieval error; the filter yields empty instead.
#
rule core_services_require_22DH
  when resourceType in %core_types
       resourceType not in %untaggable_types
       resourceType not in %excluded_types
{
    when tags exists {
        # tags present but not a usable shape (scalar/null) -> non-compliant
        tags is_struct or tags is_list
        <<result: NON_COMPLIANT; message: ssc_cbrid tag is required (tags not in a usable form)>>

        # tags delivered as a map: { "ssc_cbrid": "22DH", ... }
        when tags is_struct {
            let m = tags[ keys == "ssc_cbrid" ]
            %m not empty <<result: NON_COMPLIANT; message: ssc_cbrid tag is required>>
            %m == "22DH"  <<result: NON_COMPLIANT; message: ssc_cbrid must be 22DH for core services>>
        }

        # tags delivered as a list: [ { "key": "ssc_cbrid", "value": "22DH" } ]
        when tags is_list {
            let l = tags[ key == "ssc_cbrid" ]
            %l not empty       <<result: NON_COMPLIANT; message: ssc_cbrid tag is required>>
            %l.value == "22DH" <<result: NON_COMPLIANT; message: ssc_cbrid must be 22DH for core services>>
        }
    }
}

#
# Rule 2: WORKLOAD (everything not core/untaggable/excluded)
#   -> ssc_cbrid must be one of %workload_allowed
# Same structure and rationale as Rule 1.
#
rule workload_require_account_default
  when resourceType not in %core_types
       resourceType not in %untaggable_types
       resourceType not in %excluded_types
{
    when tags exists {
        tags is_struct or tags is_list
        <<result: NON_COMPLIANT; message: ssc_cbrid tag is required (tags not in a usable form)>>

        when tags is_struct {
            let m = tags[ keys == "ssc_cbrid" ]
            %m not empty <<result: NON_COMPLIANT; message: ssc_cbrid tag is required>>
            %m in %workload_allowed <<result: NON_COMPLIANT; message: ssc_cbrid must be a workload value>>
        }

        when tags is_list {
            let l = tags[ key == "ssc_cbrid" ]
            %l not empty <<result: NON_COMPLIANT; message: ssc_cbrid tag is required>>
            %l.value in %workload_allowed <<result: NON_COMPLIANT; message: ssc_cbrid must be a workload value>>
        }
    }
}
EOF

  trigger_types = ["ConfigurationItemChangeNotification", "OversizedConfigurationItemChangeNotification"]
}