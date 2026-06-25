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

# Config organization rule to evaluate compliancy in every member account
resource "aws_config_organization_custom_policy_rule" "ssc_cbrid" {
  name           = "require-ssc-cbrid-tag-policy"
  policy_runtime = "guard-2.x.x"
  policy_text    = <<-EOF
  #
# require-ssc-cbrid-tag  (Guard equivalent of the Lambda evaluator)
#
#   core types        -> ssc_cbrid == "22DH"
#   untaggable types  -> NOT_APPLICABLE (excluded from all rules)
#   everything else   -> ssc_cbrid in [22DI, 21JC, 22DJ]
#

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

let untaggable_types = [
  "AWS::ElasticLoadBalancingV2::Listener",
  "AWS::ElasticLoadBalancingV2::ListenerRule",
  "AWS::KMS::Alias",
  "AWS::CloudWatch::Dashboard",
  "AWS::SNS::Subscription",
  "AWS::Config::ResourceCompliance",
  "AWS::Config::ConformancePackCompliance"
]

let workload_allowed = ["22DI","21JC","22DJ"]

#
# Rule 1: CORE -> ssc_cbrid must be 22DH
#   Applies when type is in core_types AND not untaggable.
#
rule core_services_require_22DH
  when resourceType in %core_types
       resourceType not in %untaggable_types
{
    tags exists
    tags.ssc_cbrid exists
    tags.ssc_cbrid == "22DH"
}

#
# Rule 2: WORKLOAD (everything else) -> ssc_cbrid in [22DI,21JC,22DJ]
#   Applies when type is NOT core AND NOT untaggable.
#
rule workload_require_account_default
  when resourceType not in %core_types
       resourceType not in %untaggable_types
{
    tags exists
    tags.ssc_cbrid exists
    tags.ssc_cbrid in %workload_allowed
}
EOF

  trigger_types = ["ConfigurationItemChangeNotification", "OversizedConfigurationItemChangeNotification"]
}