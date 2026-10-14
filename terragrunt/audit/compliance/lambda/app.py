import csv
import json
import logging
import os
from datetime import datetime
from io import StringIO

import boto3
import urllib3
from botocore.exceptions import BotoCoreError, ClientError


def get_required_env_var(name: str) -> str:
	value = os.environ.get(name)
	if not value:
		raise EnvironmentError(f"Required environment variable {name} is missing or empty.")
	return value


config = {
	"S3_BUCKET": get_required_env_var("S3_BUCKET"),
	"MAX_RETRIES": 3,
}

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def create_boto3_clients():
	return {"s3": boto3.client("s3")}


def lambda_handler(event, context):
	logger.info("Starting S3 CSV to Slack Lambda function.")
	logger.info("Lambda timeout: %.1f seconds", context.get_remaining_time_in_millis() / 1000)

	clients = create_boto3_clients()

	try:
		result = process_s3_csv_to_slack(clients)
		logger.info("Lambda finished with status: %s", result.get("status"))
		return result
	except Exception as error:
		logger.error("Unexpected error in lambda_handler: %s", str(error), exc_info=True)
		return {"status": "error", "message": str(error)}


def process_s3_csv_to_slack(clients):
	latest_csv_key = get_latest_csv_file(clients["s3"])

	if not latest_csv_key:
		logger.info("No CSV files found in S3 bucket.")
		return {"status": "no_files", "message": "No CSV files found"}

	logger.info("Processing latest CSV file: %s", latest_csv_key)
	non_compliant_items = parse_csv_for_non_compliant(clients["s3"], latest_csv_key)

	if non_compliant_items:
		slack_webhook_url = os.environ.get("SLACK_WEBHOOK_URL")
		if slack_webhook_url:
			send_to_slack(non_compliant_items, slack_webhook_url, latest_csv_key)
		else:
			logger.warning("SLACK_WEBHOOK_URL not configured, unable to send notifications")
	else:
		logger.info("No NON_COMPLIANT items found in CSV file.")

	logger.info("Found %s NON_COMPLIANT items.", len(non_compliant_items))
	return {
		"status": "success",
		"csv_file": latest_csv_key,
		"non_compliant_count": len(non_compliant_items),
		"non_compliant_items": non_compliant_items[:100],
	}


def get_latest_csv_file(s3_client):
	"""Get the most recently modified CSV file from S3."""
	try:
		response = safe_aws_call(
			s3_client.list_objects_v2,
			"list_objects_v2",
			Bucket=config["S3_BUCKET"],
		)

		if "Contents" not in response:
			return None

		csv_files = [obj for obj in response["Contents"] if obj["Key"].endswith(".csv")]
		if not csv_files:
			return None

		latest_file = max(csv_files, key=lambda item: item["LastModified"])
		logger.info(
			"Found latest CSV file: %s (modified: %s)",
			latest_file["Key"],
			latest_file["LastModified"],
		)
		return latest_file["Key"]
	except Exception as error:
		logger.error("Error getting latest CSV file: %s", str(error))
		raise


def parse_csv_for_non_compliant(s3_client, csv_key):
	"""Download a CSV file from S3 and extract NON_COMPLIANT items."""
	try:
		response = safe_aws_call(
			s3_client.get_object,
			"get_object",
			Bucket=config["S3_BUCKET"],
			Key=csv_key,
		)
		csv_content = response["Body"].read().decode("utf-8")
		csv_reader = csv.DictReader(StringIO(csv_content))
		non_compliant_items = []

		for row in csv_reader:
			if row.get("compliance", "").strip() == "NON_COMPLIANT":
				item = {
					"accountId": row.get("accountId", "").strip(),
					"guardrail": row.get("guardrail", "").strip(),
					"controlName": row.get("controlName", "").strip(),
					"resourceType": row.get("resourceType", "").strip(),
					"resourceArn": row.get("resourceArn", "").strip(),
				}
				if item["accountId"] and item["controlName"]:
					non_compliant_items.append(item)
					logger.info(
						"Found NON_COMPLIANT item: Account %s, Control %s",
						item["accountId"],
						item["controlName"],
					)

		logger.info("Parsed %s NON_COMPLIANT items from CSV", len(non_compliant_items))
		return non_compliant_items
	except Exception as error:
		logger.error("Error parsing CSV file %s: %s", csv_key, str(error))
		raise


def safe_aws_call(function, context_message, *args, **kwargs):
	"""Call an AWS API with retries."""
	for attempt in range(1, config["MAX_RETRIES"] + 1):
		try:
			return function(*args, **kwargs)
		except ClientError as error:
			error_code = error.response.get("Error", {}).get("Code", "")
			if error_code == "AccessDeniedException":
				logger.error(
					"Access denied for %s: %s. Check the Lambda S3 permissions.",
					context_message,
					str(error),
				)
				raise

			logger.warning(
				"[Attempt %s/%s] AWS call failed (%s): %s",
				attempt,
				config["MAX_RETRIES"],
				context_message,
				str(error),
			)
			if attempt == config["MAX_RETRIES"]:
				logger.error("Max retries reached for %s. Raising exception.", context_message)
				raise
		except BotoCoreError as error:
			logger.warning(
				"[Attempt %s/%s] AWS call failed (%s): %s",
				attempt,
				config["MAX_RETRIES"],
				context_message,
				str(error),
			)
			if attempt == config["MAX_RETRIES"]:
				logger.error("Max retries reached for %s. Raising exception.", context_message)
				raise


def send_to_slack(non_compliant_items, webhook_url, csv_file):
	"""Send non-compliant items to Slack."""
	try:
		filtered_items = [
			item
			for item in non_compliant_items
			if item.get("resourceType", "").strip() != "AWS::::Account"
		]
		logger.info(
			"Filtered %s AWS::::Account items from Slack notification",
			len(non_compliant_items) - len(filtered_items),
		)

		if not filtered_items:
			logger.info("All non-compliant items were AWS::::Account type")
			return

		file_date = "Unknown"
		if "_" in csv_file:
			try:
				file_date = csv_file.split("_")[-1].replace(".csv", "")
			except (AttributeError, IndexError):
				pass

		message = {
			"text": f"AWS Guardrails Compliance Report - {len(filtered_items)} Non-Compliant Items Found",
			"blocks": [
				{
					"type": "header",
					"text": {
						"type": "plain_text",
						"text": "AWS Guardrails Compliance Report",
					},
				},
				{
					"type": "section",
					"fields": [
						{"type": "mrkdwn", "text": f"*Total Issues:*\n{len(filtered_items)} non-compliant items"},
						{"type": "mrkdwn", "text": f"*Report Date:*\n{file_date}"},
						{"type": "mrkdwn", "text": f"*Source File:*\n`{csv_file}`"},
						{
							"type": "mrkdwn",
							"text": f"*Alert Time:*\n{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}",
						},
					],
				},
				{"type": "divider"},
			],
		}

		guardrail_groups = {}
		for item in filtered_items:
			guardrail_groups.setdefault(item.get("guardrail", "Unknown"), []).append(item)

		if len(guardrail_groups) > 1:
			guardrails_text = f"*Affected Guardrails ({len(guardrail_groups)}):*\n"
			for guardrail, items in list(guardrail_groups.items())[:5]:
				guardrails_text += f"• `{guardrail}` ({len(items)} issues)\n"
			if len(guardrail_groups) > 5:
				guardrails_text += f"• ...and {len(guardrail_groups) - 5} more guardrails\n"
			message["blocks"].extend(
				[
					{"type": "section", "text": {"type": "mrkdwn", "text": guardrails_text}},
					{"type": "divider"},
				]
			)

		items_text = "*Non-Compliant Items Details:*\n"
		for item in filtered_items[:8]:
			resource_text = ""
			if item.get("resourceType"):
				resource_text = f"*Type:* `{item['resourceType']}`"
			if item.get("resourceArn"):
				arn = item["resourceArn"]
				if len(arn) > 60:
					parts = arn.split(":")
					arn = (
						f"{parts[0]}:{parts[1]}:{parts[2]}:{parts[3]}:{parts[4]}:...{parts[-1][-20:]}"
						if len(parts) >= 6
						else f"{arn[:57]}..."
					)
				resource_text += f"\n*ARN:* `{arn}`" if resource_text else f"*ARN:* `{arn}`"

			fields = [
				{"type": "mrkdwn", "text": f"*Account:* `{item['accountId']}`"},
				{
					"type": "mrkdwn",
					"text": f"*Control:* `{item['controlName']}`"
					+ (f"\n*Guardrail:* `{item['guardrail']}`" if item.get("guardrail") else ""),
				},
			]
			if resource_text:
				fields.append({"type": "mrkdwn", "text": resource_text})
			message["blocks"].append({"type": "section", "fields": fields})

		if len(filtered_items) > 8:
			items_text += f"{len(filtered_items) - 8} additional non-compliant items not shown above"
		message["blocks"].extend(
			[
				{"type": "divider"},
				{"type": "context", "elements": [{"type": "mrkdwn", "text": items_text}]},
			]
		)

		http = urllib3.PoolManager()
		response = http.request(
			"POST",
			webhook_url,
			body=json.dumps(message),
			headers={"Content-Type": "application/json"},
		)
		if response.status == 200:
			logger.info("Successfully sent %s non-compliant items to Slack", len(filtered_items))
		else:
			logger.error("Failed to send to Slack. Status: %s, Response: %s", response.status, response.data)
	except Exception as error:
		logger.error("Failed to send notification to Slack: %s", str(error))