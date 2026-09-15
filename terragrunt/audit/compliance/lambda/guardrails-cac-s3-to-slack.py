import csv
import json
import logging
import os
from datetime import datetime
from io import StringIO
import urllib3

import boto3
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
    return {
        "s3": boto3.client("s3")
    }

def lambda_handler(event, context):
    logger.info("Starting S3 CSV to Slack Lambda function.")
    logger.info(f"Lambda timeout: {context.get_remaining_time_in_millis() / 1000:.1f} seconds")
    
    clients = create_boto3_clients()
    
    try:
        result = process_s3_csv_to_slack(clients)
        logger.info("Lambda finished with status: %s", result.get("status"))
        return result
    except Exception as e:
        logger.error("Unexpected error in lambda_handler: %s", str(e), exc_info=True)
        return {"status": "error", "message": str(e)}

def process_s3_csv_to_slack(clients):
    # Get the latest CSV file from S3
    latest_csv_key = get_latest_csv_file(clients["s3"])
    
    if not latest_csv_key:
        logger.info("No CSV files found in S3 bucket.")
        return {"status": "no_files", "message": "No CSV files found"}
    
    logger.info(f"Processing latest CSV file: {latest_csv_key}")
    
    # Download and parse the CSV file
    non_compliant_items = parse_csv_for_non_compliant(clients["s3"], latest_csv_key)
    
    # Send results to Slack if webhook URL is configured
    if non_compliant_items:
        slack_webhook_url = os.environ.get("SLACK_WEBHOOK_URL")
        if slack_webhook_url:
            send_to_slack(non_compliant_items, slack_webhook_url, latest_csv_key)
        else:
            logger.warning("SLACK_WEBHOOK_URL not configured, unable to send notifications")
    else:
        logger.info("No NON_COMPLIANT items found in CSV file.")
    
    logger.info(f"Found {len(non_compliant_items)} NON_COMPLIANT items.")
    
    return {
        "status": "success",
        "csv_file": latest_csv_key,
        "non_compliant_count": len(non_compliant_items),
        "non_compliant_items": non_compliant_items[:100]  # Return first 100 items in response
    }

def get_latest_csv_file(s3_client):
    """Get the most recently modified CSV file from the S3 bucket."""
    try:
        # List all objects in the bucket
        response = safe_aws_call(
            s3_client.list_objects_v2,
            "list_objects_v2",
            Bucket=config["S3_BUCKET"]
        )
        
        if 'Contents' not in response:
            return None
        
        # Filter for CSV files and find the latest one
        csv_files = [
            obj for obj in response['Contents'] 
            if obj['Key'].endswith('.csv')
        ]
        
        if not csv_files:
            return None
        
        # Sort by LastModified date (most recent first)
        latest_file = max(csv_files, key=lambda x: x['LastModified'])
        
        logger.info(f"Found latest CSV file: {latest_file['Key']} (modified: {latest_file['LastModified']})")
        return latest_file['Key']
        
    except Exception as e:
        logger.error(f"Error getting latest CSV file: {str(e)}")
        raise

def parse_csv_for_non_compliant(s3_client, csv_key):
    """Download CSV file from S3 and extract NON_COMPLIANT items."""
    try:
        # Download the CSV file
        response = safe_aws_call(
            s3_client.get_object,
            "get_object",
            Bucket=config["S3_BUCKET"],
            Key=csv_key
        )
        
        # Read the CSV content
        csv_content = response['Body'].read().decode('utf-8')
        csv_reader = csv.DictReader(StringIO(csv_content))
        
        non_compliant_items = []
        
        for row in csv_reader:
            # Check if compliance status is NON_COMPLIANT
            compliance = row.get('compliance', '').strip()
            if compliance == 'NON_COMPLIANT':
                # Extract required fields
                non_compliant_item = {
                    "accountId": row.get('accountId', '').strip(),
                    "guardrail": row.get('guardrail', '').strip(),
                    "controlName": row.get('controlName', '').strip(),
                    "resourceType": row.get('resourceType', '').strip(),
                    "resourceArn": row.get('resourceArn', '').strip()
                }
                
                # Only add if we have at least accountId and controlName
                if non_compliant_item["accountId"] and non_compliant_item["controlName"]:
                    non_compliant_items.append(non_compliant_item)
                    logger.info(f"Found NON_COMPLIANT item: Account {non_compliant_item['accountId']}, Control {non_compliant_item['controlName']}")
        
        logger.info(f"Parsed {len(non_compliant_items)} NON_COMPLIANT items from CSV")
        return non_compliant_items
        
    except Exception as e:
        logger.error(f"Error parsing CSV file {csv_key}: {str(e)}")
        raise

def safe_aws_call(fn, context_msg, *args, **kwargs):
    """Safely call AWS API with retries."""
    delay = 1
    for attempt in range(1, config["MAX_RETRIES"] + 1):
        try:
            return fn(*args, **kwargs)
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code == 'AccessDeniedException':
                logger.error(
                    "Access denied for %s: %s. Please ensure the Lambda execution role has S3 read permissions.",
                    context_msg,
                    str(e)
                )
                raise  # Don't retry permission errors
            
            logger.warning(
                "[Attempt %s/%s] AWS call failed (%s): %s",
                attempt,
                config["MAX_RETRIES"],
                context_msg,
                str(e)
            )
            if attempt == config["MAX_RETRIES"]:
                logger.error("Max retries reached for %s. Raising exception.", context_msg)
                raise
            
        except BotoCoreError as e:
            logger.warning(
                "[Attempt %s/%s] AWS call failed (%s): %s",
                attempt,
                config["MAX_RETRIES"],
                context_msg,
                str(e)
            )
            if attempt == config["MAX_RETRIES"]:
                logger.error("Max retries reached for %s. Raising exception.", context_msg)
                raise

def send_to_slack(non_compliant_items, webhook_url, csv_file):
    """Send non-compliant items to Slack."""
    try:
        # Filter out AWS::::Account resource types for Slack display
        filtered_items = [
            item for item in non_compliant_items 
            if item.get('resourceType', '').strip() != 'AWS::::Account'
        ]
        
        logger.info(f"Filtered {len(non_compliant_items) - len(filtered_items)} AWS::::Account items from Slack notification")
        
        if not filtered_items:
            logger.info("All non-compliant items were AWS::::Account type - no Slack notification needed")
            return
        
        # Extract date from filename for better context
        file_date = "Unknown"
        if "_" in csv_file:
            try:
                date_part = csv_file.split("_")[-1].replace(".csv", "")
                file_date = date_part
            except:
                pass
        
        # Prepare Slack message with better formatting
        message = {
            "text": f"🚨 AWS Guardrails Compliance Report - {len(filtered_items)} Non-Compliant Items Found",
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": f"🚨 AWS Guardrails Compliance Report"
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": f"*📊 Total Issues:*\n{len(filtered_items)} non-compliant items"
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*📅 Report Date:*\n{file_date}"
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*📁 Source File:*\n`{csv_file}`"
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*⏰ Alert Time:*\n{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}"
                        }
                    ]
                },
                {
                    "type": "divider"
                }
            ]
        }
        
        # Group items by guardrail for better organization
        guardrail_groups = {}
        for item in filtered_items:
            guardrail = item.get('guardrail', 'Unknown')
            if guardrail not in guardrail_groups:
                guardrail_groups[guardrail] = []
            guardrail_groups[guardrail].append(item)
        
        # Add summary of guardrails affected
        if len(guardrail_groups) > 1:
            guardrails_text = f"*🎯 Affected Guardrails ({len(guardrail_groups)}):*\n"
            for guardrail, items in list(guardrail_groups.items())[:5]:  # Show up to 5 guardrails
                guardrails_text += f"• `{guardrail}` ({len(items)} issues)\n"
            if len(guardrail_groups) > 5:
                guardrails_text += f"• ...and {len(guardrail_groups) - 5} more guardrails\n"
            
            message["blocks"].append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": guardrails_text
                }
            })
            
            message["blocks"].append({
                "type": "divider"
            })
        
        # Add detailed items (up to 8 items for better readability)
        if filtered_items:
            items_text = "*🔍 Non-Compliant Items Details:*\n"
            
            for i, item in enumerate(filtered_items[:8], 1):
                # Format account info
                account_info = f"*Account:* `{item['accountId']}`"
                
                # Format control info
                control_text = f"*Control:* `{item['controlName']}`"
                if item.get('guardrail'):
                    control_text += f"\n*Guardrail:* `{item['guardrail']}`"
                
                # Format resource info
                resource_text = ""
                if item.get('resourceType'):
                    resource_text += f"*Type:* `{item['resourceType']}`"
                
                if item.get('resourceArn'):
                    arn = item['resourceArn']
                    # Smart ARN truncation - keep the resource ID part
                    if len(arn) > 60:
                        parts = arn.split(':')
                        if len(parts) >= 6:
                            # Keep account, service, region, and resource parts
                            truncated = f"{parts[0]}:{parts[1]}:{parts[2]}:{parts[3]}:{parts[4]}:...{parts[-1][-20:]}"
                        else:
                            truncated = arn[:57] + "..."
                        arn = truncated
                    
                    if resource_text:
                        resource_text += f"\n*ARN:* `{arn}`"
                    else:
                        resource_text = f"*ARN:* `{arn}`"
                
                # Combine into a nicely formatted section
                item_block = {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": account_info
                        },
                        {
                            "type": "mrkdwn", 
                            "text": control_text
                        }
                    ]
                }
                
                if resource_text:
                    item_block["fields"].append({
                        "type": "mrkdwn",
                        "text": resource_text
                    })
                
                message["blocks"].append(item_block)
                
                # Add a subtle divider between items (except for the last one)
                if i < min(8, len(filtered_items)):
                    message["blocks"].append({
                        "type": "context",
                        "elements": [
                            {
                                "type": "mrkdwn",
                                "text": "─" * 50
                            }
                        ]
                    })
            
            # Show count of additional items if there are more
            if len(filtered_items) > 8:
                message["blocks"].append({
                    "type": "context",
                    "elements": [
                        {
                            "type": "mrkdwn",
                            "text": f"📋 *{len(filtered_items) - 8} additional non-compliant items not shown above*"
                        }
                    ]
                })
        
        # Add footer with action suggestion
        message["blocks"].extend([
            {
                "type": "divider"
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": "💡 *Next Steps:* Review the non-compliant resources and take corrective action according to your organization's policies."
                    }
                ]
            }
        ])
        
        # Send to Slack
        http = urllib3.PoolManager()
        response = http.request(
            'POST',
            webhook_url,
            body=json.dumps(message),
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status == 200:
            logger.info(f"Successfully sent {len(filtered_items)} non-compliant items to Slack (filtered from {len(non_compliant_items)} total)")
        else:
            logger.error(f"Failed to send to Slack. Status: {response.status}, Response: {response.data}")
            
    except Exception as e:
        logger.error(f"Failed to send notification to Slack: {str(e)}")
        # Don't raise the exception to avoid failing the entire function
