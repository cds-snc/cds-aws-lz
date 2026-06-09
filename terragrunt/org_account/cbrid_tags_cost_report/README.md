# CBR ID Tags Cost Report

Generates a monthly AWS cost report broken down by the `ssc_cbrid` cost allocation tag. On the 3rd of each month, a Lambda function queries AWS Cost Explorer and the audit account's Config aggregator to produce per-CBR-ID cost summaries, then delivers the report via email and Slack.

## How it works

1. **EventBridge** triggers the Lambda on a monthly schedule (`cron(0 12 3 * ? *)` — 3rd of the month at 12:00 UTC).
2. **Lambda** (`cost_report`) queries:
   - **AWS Organizations** — lists all accounts and their `ssc_cbrid` tags
   - **AWS Cost Explorer** — gets unblended costs grouped by `ssc_cbrid` tag and linked account
   - **AWS Config aggregator** (`cds-cbr-tags-aggregator`) in the audit account, via cross-account role assumption, to list resources tagged with each CBR ID
3. The Lambda writes the report to **S3** in four formats: JSON, CSV, HTML, and Word (`.doc`)
4. A summary is posted to **Slack** and emailed to the configured recipients with the Word doc attached

## Architecture

```
EventBridge (monthly)
    └── Lambda (org account, 659087519042)
            ├── AWS Organizations  (list accounts + tags)
            ├── AWS Cost Explorer  (cost data)
            ├── sts:AssumeRole ──► cost-report-config-reader (audit account, 886481071419)
            │                           └── Config Aggregator (resource tag lookup)
            ├── S3 (report storage)
            ├── SES (email delivery)
            └── Slack webhook
```

## Cost breakdown logic

For each distinct `ssc_cbrid` value, two cost streams are combined:

- **Account-tagged costs** — costs from accounts whose `ssc_cbrid` Organizations tag matches the value, where the individual resource has no `ssc_cbrid` resource tag (i.e. untagged resource costs attributed by account ownership)
- **Resource-tagged costs** — costs from resources that are directly tagged with the `ssc_cbrid` resource tag

## Infrastructure

| Resource | Description |
|---|---|
| `aws_lambda_function.cost_report` | Python 3.11 Lambda, 512 MB, 5 min timeout |
| `aws_cloudwatch_event_rule.cost_report_monthly` | Monthly EventBridge trigger |
| `module.cost_report_bucket` | Versioned S3 bucket for report storage (`<billing_code>-cost-report`) |
| `aws_iam_role.cost_report` | Lambda execution role |
| `aws_iam_policy.cost_report` | Least-privilege policy (logs, CE, S3, STS, SES, Organizations) |
| `aws_cloudwatch_log_group.cost_report` | Lambda logs, 14-day retention |

The cross-account Config reader role is defined separately in [`terragrunt/audit/config/cost_report_reader_role.tf`](../../audit/config/cost_report_reader_role.tf).

## Inputs

| Variable | Description | Secret |
|---|---|---|
| `cost_report_slack_webhook_url` | Slack webhook URL to post the report summary to | Yes — `COST_REPORT_SLACK_URL` |
| `cost_report_po_numbers` | JSON map of `ssc_cbrid` values to PO numbers, e.g. `{"22DH":"2BSCS32244"}` | Yes — `COST_REPORT_PO_NUMBERS` |

GitHub Actions secrets must be set in the repository before deploying. See [tf-apply.yml](../../../.github/workflows/tf-apply.yml).

## Report formats

Reports are written to S3 under the `cost-reports/` prefix:

| File | Format | Use |
|---|---|---|
| `cost-reports/YYYY-MM.json` | JSON | Programmatic consumption |
| `cost-reports/YYYY-MM.csv` | CSV | Spreadsheet import |
| `cost-reports/YYYY-MM.html` | HTML | Browser viewing (linked from Slack) |
| `cost-reports/YYYY-MM.doc` | Word-compatible HTML | Email attachment |

## Currency and rates

All costs from Cost Explorer are in **USD**. The report also displays **CAD** values using the following constants (hardcoded in `main.py`):

| Constant | Value |
|---|---|
| `CAD_PER_USD` | 1.3808 |
| `SAVINGS_PLAN_RATE` | 10.95% enterprise savings plan discount |
| `TAX_RATE` | 13% HST |

These values should be reviewed and updated periodically.

## Deploying

```sh
cd terragrunt/org_account/cbrid_tags_cost_report
terragrunt apply
```

The `ssc_cbrid` tag must be [activated as a cost allocation tag](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/activate-built-in-tags.html) in the management account's Billing console for Cost Explorer grouping to work.
