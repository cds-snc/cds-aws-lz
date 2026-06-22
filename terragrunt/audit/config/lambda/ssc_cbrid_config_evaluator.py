"""
Custom AWS Config rule evaluator: require-ssc-cbrid-tag

Enforces the ssc_cbrid tag on every evaluated resource with split logic:
  - Platform/shared resources  → tag value must be "22DH"
  - All other resource types   → tag value must be one of "22DI", "21JC", "22DJ"

Because "all other" is evaluated by exclusion rather than enumeration, new
AWS resource types are automatically covered without any code change.
"""

import json
import datetime
import boto3

config_client = boto3.client("config")

# Resource types that belong to the shared platform / landing zone.
# These must always carry ssc_cbrid=22DH.
PLATFORM_RESOURCE_TYPES = frozenset([
    # IAM
    "AWS::IAM::Group",
    "AWS::IAM::Policy",
    "AWS::IAM::Role",
    "AWS::IAM::User",
    # VPC & networking
    "AWS::EC2::VPC",
    "AWS::EC2::Subnet",
    "AWS::EC2::RouteTable",
    "AWS::EC2::InternetGateway",
    "AWS::EC2::NetworkAcl",
    "AWS::EC2::NetworkInterface",
    "AWS::EC2::SecurityGroup",
    "AWS::EC2::CustomerGateway",
    "AWS::EC2::VPNConnection",
    "AWS::EC2::VPNGateway",
    # Load balancing
    "AWS::ElasticLoadBalancing::LoadBalancer",
    "AWS::ElasticLoadBalancingV2::LoadBalancer",
    # Security / secrets
    "AWS::KMS::Key",
    # Storage
    "AWS::S3::Bucket",
    "AWS::EC2::Volume",
    # Automation & IaC
    "AWS::CloudFormation::Stack",
    "AWS::CodeBuild::Project",
    # Messaging
    "AWS::SQS::Queue",
    "AWS::SNS::Topic",
])

PLATFORM_ALLOWED = frozenset(["22DH"])
WORKLOAD_ALLOWED = frozenset(["22DI", "21JC", "22DJ"])
TAG_KEY = "ssc_cbrid"

# Config item statuses where the resource no longer exists.
DELETED_STATUSES = frozenset([
    "ResourceDeleted",
    "ResourceNotRecorded",
    "ResourceDeletedNotRecorded",
])


def evaluate_compliance(config_item):
    """Return (compliance_type, annotation) for a single configuration item."""
    resource_type = config_item.get("resourceType", "")
    allowed = PLATFORM_ALLOWED if resource_type in PLATFORM_RESOURCE_TYPES else WORKLOAD_ALLOWED

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


def lambda_handler(event, context):
    """Entry point invoked by AWS Config on every configuration change."""
    invoking_event = json.loads(event["invokingEvent"])
    result_token = event["resultToken"]

    config_item = invoking_event.get("configurationItem")
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
