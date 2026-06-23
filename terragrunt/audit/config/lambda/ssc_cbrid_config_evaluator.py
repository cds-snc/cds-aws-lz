"""
Custom AWS Config rule evaluator: require-ssc-cbrid-tag

Enforces the ssc_cbrid tag on every evaluated resource with split logic:
  - Platform core/shared resources  → tag value must be "22DH"
  - All other resource types   → tag value must be one of "22DI", "21JC", "22DJ"

Because "all other" is evaluated by exclusion rather than enumeration, new
AWS resource types are automatically covered without any code change.
"""

import json
import datetime
import boto3

config_client = boto3.client("config")

# Exact AWS Config resource types that belong to platform core/shared services.
PLATFORM_CORE_RESOURCE_TYPES = frozenset([
    # IAM
    "AWS::IAM::Group",
    "AWS::IAM::ManagedPolicy",
    "AWS::IAM::Role",
    "AWS::IAM::User",
    "AWS::IAM::InstanceProfile",
    # Cognito
    "AWS::Cognito::UserPool",
    "AWS::Cognito::IdentityPool",
    # VPC & networking
    "AWS::EC2::VPC",
    "AWS::EC2::Subnet",
    "AWS::EC2::SecurityGroup",
    "AWS::EC2::RouteTable",
    "AWS::EC2::InternetGateway",
    "AWS::EC2::NatGateway",
    "AWS::EC2::VPCEndpoint",
    "AWS::EC2::CustomerGateway",
    "AWS::EC2::VPNConnection",
    "AWS::EC2::VPNGateway",
    # Load balancing
    "AWS::ElasticLoadBalancing::LoadBalancer",
    "AWS::ElasticLoadBalancingV2::LoadBalancer",
    "AWS::ElasticLoadBalancingV2::TargetGroup",
    "AWS::ElasticLoadBalancingV2::Listener",
    "AWS::ElasticLoadBalancingV2::ListenerRule",
    # WAF / Shield
    "AWS::WAFv2::WebACL",
    "AWS::Shield::Protection",
    # GuardDuty
    "AWS::GuardDuty::Detector",
    # KMS / secrets
    "AWS::KMS::Key",
    "AWS::KMS::Alias",
    "AWS::SecretsManager::Secret",
    # CloudWatch
    "AWS::CloudWatch::Alarm",
    "AWS::CloudWatch::Dashboard",
    "AWS::Logs::LogGroup",
    # CloudFormation
    "AWS::CloudFormation::Stack",
    "AWS::CloudFormation::StackSet",
    # Storage
    "AWS::S3::Bucket",
    "AWS::EC2::Volume",
    "AWS::EC2::Snapshot",
    # Systems Manager
    "AWS::SSM::Document",
    "AWS::SSM::Parameter",
    # Code pipeline/build
    "AWS::CodePipeline::Pipeline",
    "AWS::CodeBuild::Project",
    # Messaging
    "AWS::SQS::Queue",
    "AWS::SNS::Topic",
    "AWS::SNS::Subscription",
    # Step Functions
    "AWS::StepFunctions::StateMachine",
    "AWS::StepFunctions::Activity",
])

# Prefix-based families used for wildcard requests like aws_dx_*, aws_backup_*,
# aws_securityhub_*, aws_guardduty_*, aws_config_*, and aws_ssm_*.
PLATFORM_CORE_RESOURCE_TYPE_PREFIXES = (
    "AWS::DirectConnect::",
    "AWS::EC2::VPN",
    "AWS::GuardDuty::",
    "AWS::SecurityHub::",
    "AWS::Config::",
    "AWS::Backup::",
    "AWS::SSM::",
)

PLATFORM_CORE_ALLOWED = frozenset(["22DH"])
WORKLOAD_ALLOWED = frozenset(["22DI", "21JC", "22DJ"])
TAG_KEY = "ssc_cbrid"

# Known AWS Config resource types that do not support resource tagging.
# These are marked NOT_APPLICABLE instead of NON_COMPLIANT.
UNTAGGABLE_RESOURCE_TYPES = frozenset([
    "AWS::ElasticLoadBalancingV2::Listener",
    "AWS::ElasticLoadBalancingV2::ListenerRule",
    "AWS::KMS::Alias",
    "AWS::CloudWatch::Dashboard",
    "AWS::SNS::Subscription",
    "AWS::Config::ResourceCompliance",
    "AWS::Config::ConformancePackCompliance",
])

# Config item statuses where the resource no longer exists.
DELETED_STATUSES = frozenset([
    "ResourceDeleted",
    "ResourceNotRecorded",
    "ResourceDeletedNotRecorded",
])


def evaluate_compliance(config_item):
    """Return (compliance_type, annotation) for a single configuration item."""
    resource_type = config_item.get("resourceType", "")
    if is_untaggable_resource_type(resource_type):
        return (
            "NOT_APPLICABLE",
            f"Resource type '{resource_type}' is not taggable.",
        )

    allowed = PLATFORM_CORE_ALLOWED if is_platform_resource_type(resource_type) else WORKLOAD_ALLOWED

    tags = config_item.get("tags") or {}
    tag_value = tags.get(TAG_KEY)

    if tag_value is None:
        return (
            "NON_COMPLIANT",
            f"Required tag '{TAG_KEY}' is missing. "
            f"Expected one of: {sorted(allowed)}",
        )

    if tag_value not in allowed:
        return (
            "NON_COMPLIANT",
            f"Tag '{TAG_KEY}' has value '{tag_value}' which is not in the "
            f"allowed set for this resource type: {sorted(allowed)}",
        )

    return "COMPLIANT", f"Tag '{TAG_KEY}={tag_value}' is present and allowed."


def is_platform_resource_type(resource_type):
    """Return True when a resource type is in the platform_core/shared scope."""
    if resource_type in PLATFORM_CORE_RESOURCE_TYPES:
        return True
    return any(resource_type.startswith(prefix) for prefix in PLATFORM_CORE_RESOURCE_TYPE_PREFIXES)


def is_untaggable_resource_type(resource_type):
    """Return True when a resource type is known to not support tagging."""
    return resource_type in UNTAGGABLE_RESOURCE_TYPES


def get_configuration_item(invoking_event):
    """Return a configuration item from either regular or oversized Config events."""
    config_item = invoking_event.get("configurationItem")
    if config_item:
        return config_item

    summary = invoking_event.get("configurationItemSummary")
    if not summary:
        return None

    capture_time = summary.get("configurationItemCaptureTime")
    later_time = None
    if capture_time:
        try:
            later_time = datetime.datetime.fromisoformat(
                capture_time.replace("Z", "+00:00")
            )
        except ValueError:
            later_time = None

    response = config_client.get_resource_config_history(
        resourceType=summary["resourceType"],
        resourceId=summary["resourceId"],
        laterTime=later_time,
        limit=1,
    )
    items = response.get("configurationItems", [])
    return items[0] if items else None


def lambda_handler(event, context):
    """Entry point invoked by AWS Config on every configuration change."""
    invoking_event = json.loads(event["invokingEvent"])
    result_token = event["resultToken"]

    config_item = get_configuration_item(invoking_event)
    if not config_item:
        # Scheduled re-evaluation with no specific item — nothing to do.
        config_client.put_evaluations(Evaluations=[], ResultToken=result_token)
        return

    if config_item.get("configurationItemStatus") in DELETED_STATUSES:
        compliance = "NOT_APPLICABLE"
        annotation = "Resource has been deleted."
    else:
        compliance, annotation = evaluate_compliance(config_item)

    # Timestamps from Config are ISO-8601 strings; boto3 requires a datetime.
    raw_ts = config_item.get("configurationItemCaptureTime", "")
    try:
        ordering_ts = datetime.datetime.fromisoformat(raw_ts.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        ordering_ts = datetime.datetime.now(datetime.timezone.utc)

    print(
        f"resource={config_item['resourceType']}/{config_item['resourceId']} "
        f"compliance={compliance} annotation={annotation!r}"
    )

    config_client.put_evaluations(
        Evaluations=[
            {
                "ComplianceResourceType": config_item["resourceType"],
                "ComplianceResourceId": config_item["resourceId"],
                "ComplianceType": compliance,
                "Annotation": annotation,
                "OrderingTimestamp": ordering_ts,
            }
        ],
        ResultToken=result_token,
    )
