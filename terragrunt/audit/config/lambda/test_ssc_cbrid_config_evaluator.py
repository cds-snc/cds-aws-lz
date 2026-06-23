"""Unit tests for the custom AWS Config evaluator.

Run with:
python3 -m unittest terragrunt/audit/config/lambda/test_ssc_cbrid_config_evaluator.py
"""

import importlib.util
import pathlib
import sys
import types
import unittest
from unittest.mock import MagicMock, patch


def _load_module():
    """Load evaluator module while stubbing boto3 config client creation."""
    module_path = pathlib.Path(__file__).with_name("ssc_cbrid_config_evaluator.py")
    spec = importlib.util.spec_from_file_location("ssc_cbrid_config_evaluator", module_path)
    module = importlib.util.module_from_spec(spec)

    fake_boto3 = types.SimpleNamespace(client=lambda *_args, **_kwargs: MagicMock())
    original_boto3 = sys.modules.get("boto3")
    sys.modules["boto3"] = fake_boto3
    try:
        spec.loader.exec_module(module)
    finally:
        if original_boto3 is None:
            del sys.modules["boto3"]
        else:
            sys.modules["boto3"] = original_boto3

    return module


EVALUATOR = _load_module()


class TestPlatformCoreClassification(unittest.TestCase):
    def test_classifies_exact_platform_core_type(self):
        self.assertTrue(EVALUATOR.is_platform_resource_type("AWS::S3::Bucket"))

    def test_classifies_prefix_platform_core_type(self):
        self.assertTrue(
            EVALUATOR.is_platform_resource_type("AWS::SecurityHub::Hub")
        )

    def test_non_platform_core_type_is_workload(self):
        self.assertFalse(EVALUATOR.is_platform_resource_type("AWS::Lambda::Function"))


class TestComplianceOutcomes(unittest.TestCase):
    def test_platform_core_type_compliant_with_22dh(self):
        config_item = {
            "resourceType": "AWS::S3::Bucket",
            "tags": {"ssc_cbrid": "22DH"},
        }
        compliance, _ = EVALUATOR.evaluate_compliance(config_item)
        self.assertEqual(compliance, "COMPLIANT")

    def test_platform_core_type_non_compliant_with_workload_tag(self):
        config_item = {
            "resourceType": "AWS::S3::Bucket",
            "tags": {"ssc_cbrid": "22DI"},
        }
        compliance, annotation = EVALUATOR.evaluate_compliance(config_item)
        self.assertEqual(compliance, "NON_COMPLIANT")
        self.assertIn("22DH", annotation)

    def test_workload_type_compliant_with_allowed_value(self):
        config_item = {
            "resourceType": "AWS::Lambda::Function",
            "tags": {"ssc_cbrid": "21JC"},
        }
        compliance, _ = EVALUATOR.evaluate_compliance(config_item)
        self.assertEqual(compliance, "COMPLIANT")

    def test_workload_type_non_compliant_with_22dh(self):
        config_item = {
            "resourceType": "AWS::Lambda::Function",
            "tags": {"ssc_cbrid": "22DH"},
        }
        compliance, annotation = EVALUATOR.evaluate_compliance(config_item)
        self.assertEqual(compliance, "NON_COMPLIANT")
        self.assertIn("22DI", annotation)

    def test_missing_tag_is_non_compliant(self):
        config_item = {
            "resourceType": "AWS::EC2::Instance",
            "tags": {},
        }
        compliance, annotation = EVALUATOR.evaluate_compliance(config_item)
        self.assertEqual(compliance, "NON_COMPLIANT")
        self.assertIn("missing", annotation)

    def test_untaggable_type_is_not_applicable(self):
        config_item = {
            "resourceType": "AWS::Config::ResourceCompliance",
            "tags": {},
        }
        compliance, annotation = EVALUATOR.evaluate_compliance(config_item)
        self.assertEqual(compliance, "NOT_APPLICABLE")
        self.assertIn("not taggable", annotation)

    def test_additional_known_untaggable_types_are_not_applicable(self):
        resource_types = [
            "AWS::ElasticLoadBalancingV2::Listener",
            "AWS::ElasticLoadBalancingV2::ListenerRule",
            "AWS::KMS::Alias",
            "AWS::CloudWatch::Dashboard",
            "AWS::SNS::Subscription",
        ]
        for resource_type in resource_types:
            with self.subTest(resource_type=resource_type):
                config_item = {
                    "resourceType": resource_type,
                    "tags": {},
                }
                compliance, annotation = EVALUATOR.evaluate_compliance(config_item)
                self.assertEqual(compliance, "NOT_APPLICABLE")
                self.assertIn("not taggable", annotation)


class TestLambdaHandler(unittest.TestCase):
    def test_oversized_notification_fetches_configuration_item(self):
        EVALUATOR.config_client.reset_mock()
        EVALUATOR.config_client.get_resource_config_history.return_value = {
            "configurationItems": [
                {
                    "resourceType": "AWS::S3::Bucket",
                    "resourceId": "example-bucket",
                    "tags": {"ssc_cbrid": "22DH"},
                    "configurationItemStatus": "OK",
                    "configurationItemCaptureTime": "2026-06-23T12:00:00.000Z",
                }
            ]
        }

        event = {
            "invokingEvent": '{"configurationItemSummary": {"resourceType": "AWS::S3::Bucket", "resourceId": "example-bucket", "configurationItemCaptureTime": "2026-06-23T12:00:00.000Z"}}',
            "resultToken": "token",
        }

        with patch("builtins.print"):
            EVALUATOR.lambda_handler(event, None)

        EVALUATOR.config_client.get_resource_config_history.assert_called_once()
        EVALUATOR.config_client.put_evaluations.assert_called_once()
        evaluation = EVALUATOR.config_client.put_evaluations.call_args.kwargs[
            "Evaluations"
        ][0]
        self.assertEqual(evaluation["ComplianceType"], "COMPLIANT")
        self.assertEqual(evaluation["ComplianceResourceType"], "AWS::S3::Bucket")


if __name__ == "__main__":
    unittest.main()