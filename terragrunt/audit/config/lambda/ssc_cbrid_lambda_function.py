"""
Lambda: Report non-compliant resources for a single AWS Config rule to Slack.

Queries the 'cds-cbr-tags-aggregator' organization aggregator for one specific
rule, counts COMPLIANT and NON_COMPLIANT resources per account, and posts a
compact summary (totals + per-account compliant/non-compliant counts) to a Slack
channel via an incoming webhook. Additionally, a detailed CSV report with one line 
per evaluated resource is uploaded to S3, and a link to the report is included in 
the Slack message.
"""

import json
import os
import csv
import io
import datetime
import urllib.request
import urllib.error
from urllib.parse import quote
import boto3
from botocore.config import Config as BotoConfig


CONFIG_AGGREGATOR_NAME = os.environ.get("CONFIG_AGGREGATOR_NAME", "cds-cbr-tags-aggregator")
CONFIG_RULE_NAME = os.environ.get(
    "CONFIG_RULE_NAME", "OrgConfigRule-require-ssc-cbrid-tag-wf6xls0p"
)
CONFIG_REGION = os.environ.get("CONFIG_REGION", "ca-central-1")
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")
# S3 destination for the full CSV report. If S3_BUCKET is unset, the CSV step
# is skipped and only the summary is posted.
S3_BUCKET = os.environ.get("S3_BUCKET", "")
S3_PREFIX = os.environ.get("S3_PREFIX", "config-compliance-reports")

# Explicit timeouts so a stuck call fails fast instead of eating the whole
# Lambda timeout budget.
config_client = boto3.client(
    "config",
    config=BotoConfig(
        connect_timeout=5,
        read_timeout=15,
        retries={"max_attempts": 3, "mode": "standard"},
    ),
)
s3_client = boto3.client(
    "s3",
    region_name=CONFIG_REGION,
    config=BotoConfig(
        signature_version="s3v4",
        s3={"addressing_style": "virtual"},
    ),
)


def get_account_names():
    """Best-effort map of account_id -> account name via Organizations.

    Returns {} if the call isn't permitted; the report then uses account IDs.
    """
    names = {}
    try:
        org = boto3.client("organizations")
        paginator = org.get_paginator("list_accounts")
        for page in paginator.paginate():
            for acct in page["Accounts"]:
                names[acct["Id"]] = acct["Name"]
    except Exception as exc:  # noqa: BLE001 - non-fatal
        print(f"Could not list account names (continuing with IDs only): {exc}")
    return names


def get_accounts_for_rule():
    """Return the set of account IDs that have data for the target rule.

    Uses get_aggregate_config_rule_compliance_summary, which does not require an
    AccountId and returns per-account compliance for the aggregator. We then
    query resource details per account.
    """
    account_ids = set()
    next_token = None
    while True:
        kwargs = {
            "ConfigurationAggregatorName": CONFIG_AGGREGATOR_NAME,
            "GroupByKey": "ACCOUNT_ID",
        }
        if next_token:
            kwargs["NextToken"] = next_token

        response = config_client.get_aggregate_config_rule_compliance_summary(**kwargs)
        for item in response.get("AggregateComplianceCounts", []):
            account_ids.add(item["GroupName"])

        next_token = response.get("NextToken")
        if not next_token:
            break
    return account_ids


def _get_resources(account_id, compliance_type):
    """Return per-resource records of a compliance type for the rule in one account.

    Each record: {account_id, compliance, resource_type, resource_id, region}.
    """
    records = []
    paginator = config_client.get_paginator(
        "get_aggregate_compliance_details_by_config_rule"
    )
    page_iterator = paginator.paginate(
        ConfigurationAggregatorName=CONFIG_AGGREGATOR_NAME,
        ConfigRuleName=CONFIG_RULE_NAME,
        AccountId=account_id,
        AwsRegion=CONFIG_REGION,
        ComplianceType=compliance_type,
    )
    for page in page_iterator:
        for result in page.get("AggregateEvaluationResults", []):
            qualifier = (
                result.get("EvaluationResultIdentifier", {})
                .get("EvaluationResultQualifier", {})
            )
            records.append(
                {
                    "account_id": result.get("AccountId", account_id),
                    "compliance": compliance_type,
                    "resource_type": qualifier.get("ResourceType", "unknown"),
                    "resource_id": qualifier.get("ResourceId", "unknown"),
                    "region": result.get("AwsRegion", CONFIG_REGION),
                }
            )
    return records


def gather_all_resources():
    """Collect every evaluated resource (both compliance states) for the rule.

    Returns (all_records, counts) where:
      all_records = list of per-resource dicts (for the CSV)
      counts      = {account_id: {"compliant": int, "non_compliant": int}}
    Single pass: counts are derived from the same data used for the CSV, so we
    don't make duplicate API calls.
    """
    all_records = []
    counts = {}
    for account_id in sorted(get_accounts_for_rule()):
        nc = _get_resources(account_id, "NON_COMPLIANT")
        c = _get_resources(account_id, "COMPLIANT")
        if not nc and not c:
            continue  # rule never evaluated anything in this account
        all_records.extend(nc)
        all_records.extend(c)
        counts[account_id] = {"compliant": len(c), "non_compliant": len(nc)}
    return all_records, counts


def build_and_upload_csv(all_records, account_names):
    """Write all per-resource records to a CSV and upload to S3.

    Returns the s3:// URI of the uploaded object, or None if S3_BUCKET is unset
    or the upload fails (the summary is still posted in that case).
    """
    if not S3_BUCKET:
        print("S3_BUCKET not set \u2014 skipping CSV upload.")
        return {"uri": None, "url": None}

    # Build CSV in memory.
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(
        ["account_id", "account_name", "compliance", "resource_type",
         "resource_id", "region", "rule"]
    )
    for r in all_records:
        writer.writerow(
            [
                r["account_id"],
                account_names.get(r["account_id"], ""),
                r["compliance"],
                r["resource_type"],
                r["resource_id"],
                r["region"],
                CONFIG_RULE_NAME,
            ]
        )

    body = buffer.getvalue().encode("utf-8")

    # Timestamped key: <prefix>/YYYY/MM/DD/<rule>-<timestamp>.csv
    now = datetime.datetime.now(datetime.timezone.utc)
    key = (
        f"{S3_PREFIX}/{now:%Y/%m/%d}/"
        f"{CONFIG_RULE_NAME}-{now:%Y%m%dT%H%M%SZ}.csv"
    )

    try:
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=key,
            Body=body,
            ContentType="text/csv",
        )
    except Exception as exc:  # noqa: BLE001 - non-fatal; still post summary
        print(f"CSV upload to s3://{S3_BUCKET}/{key} failed: {exc}")
        return {"uri": None, "url": None}

    uri = f"s3://{S3_BUCKET}/{key}"
    print(f"Uploaded CSV ({len(all_records)} rows, {len(body)} bytes) to {uri}")

    # Build an S3 console URL. This requires the clicker/user clicking the link
    # to be authenticated in the AWS account with S3 read access to the object,
    # so only people with access to the account can download the report.
    console_url = (
        f"https://{CONFIG_REGION}.console.aws.amazon.com/s3/object/"
        f"{S3_BUCKET}?region={CONFIG_REGION}&bucketType=general"
        f"&prefix={quote(key, safe='')}"
    )

    return {"uri": uri, "url": console_url}


def format_slack_message(counts, account_names, report=None):
    """Build a COMPACT message: org-wide totals plus the top N worst accounts.

    `counts` is {account_id: {"compliant": int, "non_compliant": int}}.
    The receiving bot rejects large request bodies, so this deliberately sends
    only totals and a small fixed-size list of the worst offenders rather than
    one line per account (which fails if many accounts exist in the org). 
    """
    if not counts:
        text = (
            f":information_source: *{CONFIG_RULE_NAME}*\n"
            f"No evaluated resources found in the aggregator for this rule."
        )
        return {"blocks": [{"type": "section",
                            "text": {"type": "mrkdwn", "text": text}}]}

    total_non_compliant = sum(c["non_compliant"] for c in counts.values())
    total_compliant = sum(c["compliant"] for c in counts.values())
    total_resources = total_non_compliant + total_compliant
    accounts_with_nc = sum(1 for c in counts.values() if c["non_compliant"] > 0)

    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "AWS SSC CBRid tag Compliance Summary",
                "emoji": True,
            },
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": (
                    f"*Rule:* `{CONFIG_RULE_NAME}`\n"
                    f"*Total resources evaluated:* {total_resources}\n"
                    f"\u2705 *Compliant:* {total_compliant}    "
                    f"\u274c *Non-compliant:* {total_non_compliant}\n"
                    f"*Accounts evaluated:* {len(counts)}    "
                    f"*Accounts with non-compliance:* {accounts_with_nc}"
                ),
            },
        },
        {"type": "divider"},
    ]

    # Top N worst accounts by non-compliant count. Fixed size keeps the body
    # small regardless of how many accounts exist in the org.
    top_n = int(os.environ.get("TOP_N_ACCOUNTS", "10"))
    ordered = sorted(
        counts.items(), key=lambda kv: kv[1]["non_compliant"], reverse=True
    )[:top_n]

    lines = []
    for account_id, c in ordered:
        name = account_names.get(account_id, account_id)
        lines.append(
            f"\u2022 *{name}*: "
            f"\u2705 {c['compliant']}  /  "
            f"\u274c {c['non_compliant']}"
        )

    blocks.append(
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Top {len(lines)} accounts by non-compliance:*\n"
                        + "\n".join(lines),
            },
        }
    )

    if report and report.get("url"):
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*<{report['url']}|\U0001F4C4 Open full report (CSV) "
                            f"in S3 console>*\n"
                            f"_Requires AWS sign-in to the account._",
                },
            }
        )
    elif report and report.get("uri"):
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Full report (CSV):* `{report['uri']}`",
                },
            }
        )

    blocks.append(
        {
            "type": "context",
            "elements": [
                {"type": "mrkdwn",
                 "text": "\u2705 = compliant   \u274c = non-compliant"}
            ],
        }
    )

    return {"blocks": blocks}


def post_to_slack(message):
    """POST the message payload to the Slack incoming webhook."""
    if not SLACK_WEBHOOK_URL:
        raise ValueError("SLACK_WEBHOOK_URL environment variable is not set")

    url = SLACK_WEBHOOK_URL
    stripped = url.strip().strip('"').strip("'")
    print(
        f"Webhook check: len={len(url)} stripped_len={len(stripped)} "
        f"startswith_https={stripped.startswith('https://hooks.slack.com/')} "
        f"has_leading_trailing_ws={url != url.strip()} "
        f"prefix={stripped[:34]!r}"
    )
    effective_url = stripped

    data = json.dumps(message).encode("utf-8")
    print(f"Slack payload bytes: {len(data)}; blocks: {len(message.get('blocks', []))}")
    req = urllib.request.Request(
        effective_url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "User-Agent": "config-compliance-report/1.0",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8")
            if resp.status != 200 or body != "ok":
                print(f"Slack returned status={resp.status} body={body}")
            return resp.status
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8")
        print(f"Slack rejected request: HTTP {exc.code} \u2014 {detail}")
        raise
    except urllib.error.URLError as exc:
        print(f"Slack webhook URLError: {exc.reason}")
        raise


def lambda_handler(event, context):
    """Entry point."""
    print(f"Querying rule '{CONFIG_RULE_NAME}' in aggregator "
          f"'{CONFIG_AGGREGATOR_NAME}' ({CONFIG_REGION})")

    all_records, counts = gather_all_resources()
    total_nc = sum(c["non_compliant"] for c in counts.values())
    total_c = sum(c["compliant"] for c in counts.values())
    print(f"Accounts: {len(counts)} | compliant: {total_c} | "
          f"non-compliant: {total_nc} | total rows: {len(all_records)}")

    account_names = get_account_names()

    # Write the full per-resource detail to a CSV in S3 (if configured) and get
    # a clickable download link.
    report = build_and_upload_csv(all_records, account_names)

    message = format_slack_message(counts, account_names, report=report)

    print("Posting to Slack")
    status = post_to_slack(message)

    summary = {
        "rule": CONFIG_RULE_NAME,
        "accounts": len(counts),
        "compliant_resources": total_c,
        "noncompliant_resources": total_nc,
        "csv_uri": report.get("uri"),
        "slack_status": status,
    }
    print(json.dumps(summary))
    return {"statusCode": 200, "body": json.dumps(summary)}


if __name__ == "__main__":
    print(lambda_handler({}, None))