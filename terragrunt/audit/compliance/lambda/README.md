# AWS S3 CSV to Slack Lambda Function

This Lambda function reads CSV files from an S3 bucket, finds the latest one, extracts NON_COMPLIANT items, filters out AWS::::Account resource types, and sends professionally formatted notifications to Slack.

## Function Overview

The function:
1. **Connects to S3 bucket** (configurable via environment variable)
2. **Finds the latest CSV file** based on last modified date
3. **Parses the CSV** and extracts rows where `compliance = "NON_COMPLIANT"`
4. **Filters AWS::::Account items** to reduce noise in notifications
5. **Extracts specific fields**: `accountId`, `guardrail`, `controlName`, `resourceType`, `resourceArn`
6. **Sends a formatted Slack notification** with grouped and organized compliance alerts

## 🔧 **Configuration**

### **Required Configuration in terraform.tfvars:**
```hcl
# AWS Configuration
aws_region     = "ca-central-1"
aws_account_id = "886481071419"

# S3 bucket containing the CSV compliance files
s3_bucket_name = "gc-fedclient-886481071419-ca-central-1"

# Slack webhook URL for notifications
slack_webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

### **Optional Configuration:**
```hcl
# Environment and tagging
environment   = "prod"
billing_code  = "guardrails"

# Monitoring configuration
log_retention_days = 14

# Scheduling (5am PST = 13:00 UTC)
schedule_expression = "cron(0 13 * * ? *)"


## 📋 **What Gets Deployed**

The Terraform configuration creates:

### **Core Lambda Resources:**
- **Lambda Function**: `guardrails-cac-s3-csv-to-slack`
- **IAM Role & Policies**: Least-privilege access to S3 and CloudWatch
- **CloudWatch Log Group**: 14-day retention by default

### **Scheduling & Monitoring:**
- **EventBridge Rule**: Daily execution at 5am PST
- **CloudWatch Alarms**: Error and duration monitoring
- **SNS Topic**: Encrypted notifications for alarm alerts

### **Security Features:**
- **KMS Encryption**: SNS topic encrypted with AWS managed key
- **Account Validation**: Restricts access to your AWS account only
- **Least Privilege IAM**: Only required S3 and logging permissions

## 🔔 **Automated Scheduling**

The function automatically runs daily at **5:00 AM PST** (13:00 UTC) via EventBridge.

**Note**: The schedule uses fixed UTC time. During PDT, it runs at 6:00 AM local time. For year-round 5:00 AM, manually adjust the cron expression for DST.

## 📧 **Notifications**

### **Slack Notifications**
- Professional formatting with organized sections
- Groups items by guardrail for better readability
- Shows up to 8 detailed items (more available in logs)
- Filters out `AWS::::Account` resource types to reduce noise
- Smart ARN truncation for better display

### **Slack Formatting**
```
🚨 AWS Guardrails Compliance Alert - 3 Non-Compliant Items Found

📊 Total Issues: 3 non-compliant items
📅 Report Date: 2025-08-05
📁 Source File: compliance_report_2025-08-05.csv
⏰ Alert Time: 2025-08-05 14:30:00 UTC

🎯 Affected Guardrails (2):
• Protection of Data-in-Transit (2 issues)
• Manage Access (1 issue)

🔍 Non-Compliant Items Details:
[Detailed resource information with smart formatting]
```

## 🔍 **Function Behavior**

### **Latest File Selection**
- Lists all objects in the S3 bucket
- Filters for `.csv` files
- Selects file with most recent `LastModified` timestamp
- Logs file selection for audit trail

### **Data Processing**
- Downloads latest CSV file using retry logic
- Parses with Python's `csv.DictReader`
- Filters for `compliance == "NON_COMPLIANT"`
- Validates required fields before processing
- Returns up to 100 items in Lambda response

### **Error Handling**
- Comprehensive retry logic for AWS API calls
- Graceful handling of missing files or permissions
- Detailed logging for troubleshooting
- CloudWatch alarms for monitoring

## 📊 **Expected CSV Format**

```csv
accountId,guardrail,controlName,resourceType,resourceArn,compliance
123456789012,07-Protection of Data-in-Transit,gc07_check_certificate_authorities,AWS::ACM::Certificate,arn:aws:acm:ca-central-1:123456789012:certificate/abc123,NON_COMPLIANT
987654321098,02-Manage Access,gc02_check_iam_password_policy,AWS::::Account,987654321098,NON_COMPLIANT
```

### **Required Columns:**
- `accountId` - AWS Account ID
- `guardrail` - Guardrail identifier  
- `controlName` - Control name
- `resourceType` - AWS resource type
- `resourceArn` - AWS resource ARN
- `compliance` - Compliance status (filters for "NON_COMPLIANT")

## 🚨 **Monitoring & Alerting**

### **CloudWatch Alarms:**
- **Error Alarm**: Triggers on any Lambda function errors
- **Duration Alarm**: Triggers if execution exceeds 4 minutes
- **SNS Integration**: Sends notifications via encrypted SNS topic

### **CloudWatch Logs:**
- **Log Group**: `/aws/lambda/guardrails-cac-s3-csv-to-slack`
- **Retention**: 14 days (configurable)
- **Structured Logging**: JSON format for easy parsing