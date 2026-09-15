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

## 🚀 **Deployment (Recommended: Terraform)**

### **Prerequisites**
- Terraform >= 1.5
- AWS CLI configured with appropriate credentials
- Terragrunt (if using the provided configuration)

### **Quick Deployment with Terragrunt**
```bash
# Navigate to terraform directory
cd terraform/

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy everything
terragrunt plan
terragrunt apply
```

### **Manual Terraform Deployment**
```bash
# Navigate to terraform directory
cd terraform/

# Initialize Terraform
terraform init

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan and apply
terraform plan
terraform apply
```

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

### **Email Notifications (Optional)**
- CloudWatch alarm notifications via SNS
- Alerts for Lambda errors and long execution times
- Subscribe by setting `alert_email` in terraform.tfvars

## 🎯 **Enhanced Features**

### **Smart Filtering**
- **AWS::::Account Exclusion**: Filters out account-level compliance items
- **Resource-Specific Alerts**: Focus on actionable resource violations
- **Early Exit Logic**: No notification if all items are account-level

### **Professional Slack Formatting**
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

## 🧪 **Testing**

### **Manual Invocation:**
```bash
aws lambda invoke \
  --function-name guardrails-cac-s3-csv-to-slack \
  --payload '{"source":"manual-test"}' \
  response.json && cat response.json
```

### **Expected Response:**
```json
{
  "status": "success",
  "csv_file": "compliance_report_2025-08-05.csv",
  "non_compliant_count": 3,
  "non_compliant_items": [
    {
      "accountId": "123456789012",
      "guardrail": "07-Protection of Data-in-Transit",
      "controlName": "gc07_check_certificate_authorities",
      "resourceType": "AWS::ACM::Certificate",
      "resourceArn": "arn:aws:acm:ca-central-1:123456789012:certificate/abc123"
    }
  ]
}
```

## 🚨 **Monitoring & Alerting**

### **CloudWatch Alarms:**
- **Error Alarm**: Triggers on any Lambda function errors
- **Duration Alarm**: Triggers if execution exceeds 4 minutes
- **SNS Integration**: Sends notifications via encrypted SNS topic

### **CloudWatch Logs:**
- **Log Group**: `/aws/lambda/guardrails-cac-s3-csv-to-slack`
- **Retention**: 14 days (configurable)
- **Structured Logging**: JSON format for easy parsing

## 🔧 **Troubleshooting**

### **Common Issues:**

**No CSV Files Found**
```
Check: S3 bucket exists, contains .csv files, Lambda has s3:ListBucket permission
```

**Access Denied Errors**
```
Check: IAM policy attached, bucket policy allows access, correct bucket name
```

**No Slack Notifications**
```
Check: SLACK_WEBHOOK_URL set, webhook URL valid, test manually with curl
```

**Function Timeouts**
```
Check: CloudWatch duration alarm, increase timeout if needed, optimize processing
```

### **Logs Analysis:**
```bash
# View recent logs
aws logs describe-log-streams \
  --log-group-name /aws/lambda/guardrails-cac-s3-csv-to-slack \
  --order-by LastEventTime --descending

# Get specific log events
aws logs get-log-events \
  --log-group-name /aws/lambda/guardrails-cac-s3-csv-to-slack \
  --log-stream-name [STREAM_NAME]
```

## 🎯 **Legacy Deployment (Manual)**

<details>
<summary>Click to expand manual deployment instructions</summary>
```bash
cd src/lambda/aws_s3_csv_to_slack
zip -r s3-csv-slack-lambda.zip app.py requirements.txt
```

### 2. Create the Lambda function:
```bash
aws lambda create-function \
  --function-name s3-csv-to-slack \
  --runtime python3.9 \
  --role arn:aws:iam::YOUR_ACCOUNT:role/YOUR_LAMBDA_ROLE \
  --handler app.lambda_handler \
  --zip-file fileb://s3-csv-slack-lambda.zip \
  --timeout 60 \
  --memory-size 256
```

### 3. Set environment variables:
```bash
aws lambda update-function-configuration \
  --function-name s3-csv-to-slack \
  --environment Variables='{
    "S3_BUCKET":"gc-fedclient-886481071419-ca-central-1",
    "SLACK_WEBHOOK_URL":"https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  }'
```

### 4. Attach IAM policy:
```bash
aws iam put-role-policy \
  --role-name YOUR_LAMBDA_ROLE \
  --policy-name S3CSVToSlackPolicy \
  --policy-document file://iam-policy.json
```

### **1. Package the Lambda function:**
```bash
cd src/lambda/aws_s3_csv_to_slack
zip -r s3-csv-slack-lambda.zip app.py requirements.txt
```

### **2. Create the Lambda function:**
```bash
aws lambda create-function \
  --function-name guardrails-cac-s3-csv-to-slack \
  --runtime python3.9 \
  --role arn:aws:iam::YOUR_ACCOUNT:role/YOUR_LAMBDA_ROLE \
  --handler app.lambda_handler \
  --zip-file fileb://s3-csv-slack-lambda.zip \
  --timeout 300 \
  --memory-size 512
```

### **3. Set environment variables:**
```bash
aws lambda update-function-configuration \
  --function-name guardrails-cac-s3-csv-to-slack \
  --environment Variables='{
    "S3_BUCKET":"gc-fedclient-886481071419-ca-central-1",
    "SLACK_WEBHOOK_URL":"https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  }'
```

### **4. Attach IAM policy:**
```bash
aws iam put-role-policy \
  --role-name YOUR_LAMBDA_ROLE \
  --policy-name S3CSVToSlackPolicy \
  --policy-document file://iam-policy.json
```

</details>

## 💰 **Cost Considerations**

### **Estimated Monthly Cost:**
- **Lambda**: ~$1-3 USD (daily execution, 5-minute runtime)
- **CloudWatch Logs**: ~$1 USD (14-day retention)
- **SNS**: Free tier covers alarm notifications
- **EventBridge**: Minimal cost for daily triggers

**Total**: < $5 USD/month for daily compliance monitoring

## 🚀 **Future Enhancements**

The infrastructure is ready for:
- **Multi-Region Deployment**: Deploy to multiple AWS regions
- **Multiple Notification Channels**: PagerDuty, Microsoft Teams integration
- **Custom Filtering**: Environment-specific compliance rules
- **Dashboard Integration**: CloudWatch dashboard for metrics
- **Advanced Scheduling**: Multiple schedules for different report types

---

## 📚 **Related Documentation**

- **[Terraform Configuration](../../README.md)** - Main deployment documentation
- **[SNS Implementation](../../SNS_IMPLEMENTATION.md)** - Notification setup details
- **[Lambda Path Fix](../../LAMBDA_PATH_FIX.md)** - Terragrunt compatibility notes
- **[Architecture Improvements](../../IMPROVEMENTS.md)** - Best practices implemented
