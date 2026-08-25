"""
Generate a monthly cost report grouped by the ssc_cbrid tag.
For each distinct tag value, shows account-level costs (sum of costs from
accounts tagged with that value) and resource-level costs (sum of costs
from resources tagged with that value).
Writes the report to S3 and posts a summary to Slack.
"""

import csv
import io
import json
import logging
import os
from datetime import date
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from html import escape
from http.client import HTTPSConnection
from urllib.parse import urlparse

import boto3

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

ce = boto3.client("ce", region_name="us-east-1")
orgs = boto3.client("organizations")
s3 = boto3.client("s3")
ses = boto3.client("ses")
invoicing = boto3.client("invoicing", region_name="us-east-1")

TARGET_BUCKET = os.getenv("TARGET_BUCKET")
REPORT_PREFIX = "cost-reports"
COST_REPORT_SLACK_WEBHOOK_URL = os.getenv("COST_REPORT_SLACK_WEBHOOK_URL")
CONFIG_READER_ROLE_ARN = "arn:aws:iam::886481071419:role/cost-report-config-reader"
CONFIG_AGGREGATOR_NAME = "cds-cbr-tags-aggregator"
CONFIG_AGGREGATOR_REGION = "ca-central-1"
SENDER_EMAIL = "sre-ifs@cds-snc.ca"
RECIPIENT_EMAILS = "billing@cds-snc.ca"
TAG_KEY = "ssc_cbrid"
UNTAGGED_LABEL = "Not tagged"
# Accounts whose names start with any of these prefixes are excluded from the report.
EXCLUDED_ACCOUNT_PREFIXES = ("GCSignin", "DigitalCredentials", "CanadaLogin")
SAVINGS_PLAN_RATE = 0.1095  # Enterprise savings plan discount
TAX_RATE = 0.13  # HST included in the invoiced amounts
COST_REPORT_PO_NUMBERS = json.loads(os.getenv("COST_REPORT_PO_NUMBERS", "{}"))

# AWS returns several invoice summaries for one billing period -- the Amazon
# Web Services Canada tax invoice (CAIN*), an AWS Inc. invoice (AWSI-INV-*),
# and a payment record -- and they do not all carry the same exchange rate.
# The CAIN* invoice is the HST tax invoice that is actually paid, so its rate
# is the definitive one. Override via env var if AWS changes the numbering.
TAX_INVOICE_ID_PREFIX = os.getenv("TAX_INVOICE_ID_PREFIX", "CAIN")

# Cost Explorer returns unrounded amounts; the invoice rounds every service
# line to the cent before summing, so the two totals drift by a few cents that
# cannot be traced to any single line item. Park that residual on one CBR ID so
# the report ties exactly to the invoice, and refuse to do so if the gap is
# larger than rounding can explain (which would mean a real reporting error).
RECONCILIATION_CBRID = os.getenv("RECONCILIATION_CBRID", "22DH")
RECONCILIATION_TOLERANCE = float(os.getenv("RECONCILIATION_TOLERANCE", "5.00"))

DISPLAY_CURRENCY_CODE = "USD"
USD_TO_DISPLAY_RATE = 1.0
# Exact rate string as printed on the invoice, plus its provenance, so every
# report can be reconciled against the invoice PDF it was derived from.
DISPLAY_RATE_TEXT = "1"
RATE_SOURCE = "not resolved"


def handler(event, context):
    global DISPLAY_CURRENCY_CODE, USD_TO_DISPLAY_RATE, DISPLAY_RATE_TEXT, RATE_SOURCE

    start, end, label = previous_month_range()
    # Use the report month itself for invoice currency context.
    (
        DISPLAY_CURRENCY_CODE,
        USD_TO_DISPLAY_RATE,
        DISPLAY_RATE_TEXT,
        RATE_SOURCE,
        invoice_totals,
    ) = get_invoice_currency_context(start)

    accounts = get_accounts_with_tags()

    excluded_account_ids = {
        account_id
        for account_id, info in accounts.items()
        if info["name"] and info["name"].startswith(EXCLUDED_ACCOUNT_PREFIXES)
    }
    if excluded_account_ids:
        logger.info(
            "Excluding %d account(s) from the report: %s",
            len(excluded_account_ids),
            ", ".join(sorted(accounts[aid]["name"] for aid in excluded_account_ids)),
        )

    try:
        costs_by_account_tag = get_costs_by_account_and_tag(start, end)
    except Exception as err:
        logger.warning(
            "Could not fetch costs grouped by account and tag. "
            "Is ssc_cbrid activated as a cost allocation tag? Error: %s",
            err,
        )
        costs_by_account_tag = {}

    untagged_per_account = {}
    resource_costs_by_tag = {}
    for (account_id, tag_value), cost in costs_by_account_tag.items():
        if account_id in excluded_account_ids:
            continue
        if tag_value == "":
            untagged_per_account[account_id] = untagged_per_account.get(account_id, 0.0) + cost
        else:
            resource_costs_by_tag[tag_value] = resource_costs_by_tag.get(tag_value, 0.0) + cost

    grouped = {}
    for account_id, info in accounts.items():
        if account_id in excluded_account_ids:
            continue
        if not info["tag"]:
            continue
        account_tag = info["tag"]
        untagged_cost = untagged_per_account.get(account_id, 0.0)
        group = grouped.setdefault(account_tag, {"accounts": [], "account_total": 0.0})
        group["accounts"].append({"id": account_id, "name": info["name"], "cost": untagged_cost})
        group["account_total"] += untagged_cost

    all_tag_values = set(grouped.keys()) | set(resource_costs_by_tag.keys())

    breakdown = []
    for tag_value in all_tag_values:
        group = grouped.get(tag_value, {"accounts": [], "account_total": 0.0})
        resource_cost = resource_costs_by_tag.get(tag_value, 0.0)
        total = group["account_total"] + resource_cost
        breakdown.append({
            "ssc_cbrid": tag_value,
            "total": round(total, 2),
            "account_costs": round(group["account_total"], 2),
            "resource_costs": round(resource_cost, 2),
            "accounts": [
                {"id": a["id"], "name": a["name"], "cost": round(a["cost"], 2)}
                for a in sorted(group["accounts"], key=lambda x: x["cost"], reverse=True)
            ],
        })

    breakdown.sort(key=lambda x: x["total"], reverse=True)
    grand_total = sum(b["total"] for b in breakdown)

    reconciliation = reconcile_to_invoice(breakdown, grand_total, invoice_totals)
    if reconciliation:
        grand_total = sum(b["total"] for b in breakdown)

    tag_values = [b["ssc_cbrid"] for b in breakdown]
    try:
        resources_by_tag = get_resources_for_tags(tag_values)
    except Exception as err:
        logger.warning("Could not fetch resources from Config aggregator: %s", err)
        resources_by_tag = {}

    for entry in breakdown:
        entry["resources"] = resources_by_tag.get(entry["ssc_cbrid"], [])

    report = {
        "period": label,
        "generated": date.today().isoformat(),
        "breakdown": breakdown,
        "grand_total": round(grand_total, 2),
        "reconciliation": reconciliation,
    }

    report_key = f"{REPORT_PREFIX}/{label}.json"
    s3.put_object(
        Bucket=TARGET_BUCKET,
        Key=report_key,
        Body=json.dumps(report, indent=2),
        ContentType="application/json",
    )
    logger.info("Report saved to s3://%s/%s", TARGET_BUCKET, report_key)

    csv_key = f"{REPORT_PREFIX}/{label}.csv"
    s3.put_object(
        Bucket=TARGET_BUCKET,
        Key=csv_key,
        Body=build_csv(report),
        ContentType="text/csv",
    )
    logger.info("CSV report saved to s3://%s/%s", TARGET_BUCKET, csv_key)

    html_key = f"{REPORT_PREFIX}/{label}.html"
    s3.put_object(
        Bucket=TARGET_BUCKET,
        Key=html_key,
        Body=build_html(report),
        ContentType="text/html",
    )
    logger.info("HTML report saved to s3://%s/%s", TARGET_BUCKET, html_key)

    doc_key = f"{REPORT_PREFIX}/{label}.doc"
    doc_bytes = build_doc(report).encode("utf-8")
    s3.put_object(
        Bucket=TARGET_BUCKET,
        Key=doc_key,
        Body=doc_bytes,
        ContentType="application/msword",
    )
    logger.info("DOC report saved to s3://%s/%s", TARGET_BUCKET, doc_key)

    if SENDER_EMAIL and RECIPIENT_EMAILS:
        try:
            send_email_with_doc(report, doc_bytes, label)
        except Exception as err:
            logger.warning("Failed to send email: %s", err)

    if COST_REPORT_SLACK_WEBHOOK_URL:
        html_url = s3_console_url(TARGET_BUCKET, html_key)
        post_to_slack(COST_REPORT_SLACK_WEBHOOK_URL, build_slack_message(report, html_url))

    return {"statusCode": 200, "body": json.dumps({"report_key": report_key})}


def get_accounts_with_tags():
    accounts = []
    response = orgs.list_accounts()
    accounts += response["Accounts"]
    while "NextToken" in response:
        response = orgs.list_accounts(NextToken=response["NextToken"])
        accounts += response["Accounts"]

    results = {}
    for account in accounts:
        tags = orgs.list_tags_for_resource(ResourceId=account["Id"])["Tags"]
        cbrid = next((t["Value"] for t in tags if t["Key"] == TAG_KEY), None)
        results[account["Id"]] = {"name": account["Name"], "tag": cbrid}
    return results


def get_invoice_currency_context(reference_date):
    """
    Resolve the payer's invoice currency and USD conversion rate for the
    billing month represented by `reference_date` (YYYY-MM-DD).

    AWS issues the invoice for a billing period on the 1st of the following
    month, so the rate returned here is the one printed on that invoice --
    the July report uses the rate from the invoice dated August 1.

    Returns (currency_code, rate, exact_rate_text, provenance).

    Raises RuntimeError when no unambiguous rate can be determined. Emailing a
    report whose figures are silently unconverted is worse than not sending one.
    """
    year, month, _ = reference_date.split("-", 2)
    payer_account_id = boto3.client("sts").get_caller_identity()["Account"]

    response = invoicing.list_invoice_summaries(
        Filter={"BillingPeriod": {"Year": int(year), "Month": int(month)}},
        Selector={"ResourceType": "ACCOUNT_ID", "Value": payer_account_id},
        MaxResults=100,
    )
    summaries = response.get("InvoiceSummaries", [])
    if not summaries:
        raise RuntimeError(
            f"No invoice summaries for payer {payer_account_id} for billing period "
            f"{year}-{month}. The invoice is issued on the 1st of the following "
            f"month; if this run is too early, retry once it is available."
        )

    amount_fields = ("PaymentCurrencyAmount", "TaxCurrencyAmount", "BaseCurrencyAmount")
    candidates = []
    currency_codes = set()

    # Log every rate on every summary: this is the audit trail that lets a
    # report be tied back to the invoice PDF it came from.
    for summary in summaries:
        invoice_id = summary.get("InvoiceId") or "unknown"
        issued = str(summary.get("IssuedDate") or "")[:10]
        for field in amount_fields:
            amount_obj = summary.get(field)
            if not amount_obj:
                continue
            currency_codes.add(amount_obj.get("CurrencyCode"))
            exchange = amount_obj.get("CurrencyExchangeDetails") or {}
            raw_rate = exchange.get("Rate")
            source_currency = exchange.get("SourceCurrencyCode")
            target_currency = exchange.get("TargetCurrencyCode")
            logger.info(
                "Invoice %s (issued %s) %s: currency=%s exchange=%s->%s rate=%s",
                invoice_id, issued, field,
                amount_obj.get("CurrencyCode"), source_currency, target_currency, raw_rate,
            )
            if source_currency != "USD" or raw_rate in (None, ""):
                continue
            try:
                rate = float(raw_rate)
            except (TypeError, ValueError):
                continue
            if rate <= 0:
                continue
            try:
                total = float(amount_obj["TotalAmount"])
            except (KeyError, TypeError, ValueError):
                total = None
            candidates.append({
                "invoice_id": invoice_id,
                "issued": issued,
                "currency": target_currency or amount_obj.get("CurrencyCode") or "USD",
                "rate": rate,
                "raw_rate": str(raw_rate),
                "total": total,
            })

    if not candidates:
        # A payer billed in USD has nothing to convert; that is not an error.
        if currency_codes <= {"USD", None}:
            logger.info("Payer %s is invoiced in USD; no conversion applied.", payer_account_id)
            return "USD", 1.0, "1", f"invoiced in USD ({year}-{month})"
        raise RuntimeError(
            f"Payer {payer_account_id} is invoiced in {sorted(c for c in currency_codes if c)} "
            f"for {year}-{month} but no USD exchange rate was present on any invoice summary."
        )

    # Narrow to the tax invoice that is actually paid; the other summaries for
    # the same period carry a different rate.
    preferred = [
        c for c in candidates if c["invoice_id"].startswith(TAX_INVOICE_ID_PREFIX)
    ]
    if preferred:
        ignored = sorted({
            c["invoice_id"] for c in candidates
            if not c["invoice_id"].startswith(TAX_INVOICE_ID_PREFIX)
        })
        if ignored:
            logger.info(
                "Preferring %s* tax invoice(s); ignoring rate(s) from %s",
                TAX_INVOICE_ID_PREFIX, ", ".join(ignored),
            )
        candidates = preferred
    else:
        logger.warning(
            "No %s* tax invoice for %s-%s; falling back to all summaries.",
            TAX_INVOICE_ID_PREFIX, year, month,
        )

    # Compare numerically: the same rate comes back at differing precision
    # across summaries ("1.4152019" vs "1.415201900").
    distinct_rates = {round(c["rate"], 10) for c in candidates}
    if len(distinct_rates) > 1:
        detail = "; ".join(
            f"{inv} (issued {iss}) {raw} {ccy}"
            for inv, iss, raw, ccy in sorted({
                (c["invoice_id"], c["issued"], c["raw_rate"], c["currency"])
                for c in candidates
            })
        )
        raise RuntimeError(
            f"Conflicting USD exchange rates for payer {payer_account_id} for "
            f"{year}-{month}: {detail}. Refusing to guess which invoice to use."
        )

    # Keep the most precise spelling of the agreed rate for display.
    chosen = max(candidates, key=lambda c: len(c["raw_rate"]))
    provenance = f"invoice {chosen['invoice_id']}, issued {chosen['issued']}"
    logger.info(
        "Using exchange rate 1 USD = %s %s from %s",
        chosen["raw_rate"], chosen["currency"], provenance,
    )

    # Invoiced totals in the display currency, for the rounding reconciliation.
    # More than one invoice can come back for a period, so keep them all and let
    # the caller match on the one whose total is within rounding distance.
    totals = {
        c["invoice_id"]: {
            "invoice_id": c["invoice_id"],
            "issued": c["issued"],
            "total": c["total"],
        }
        for c in candidates
        if c["total"] is not None and c["currency"] == chosen["currency"]
    }
    if totals:
        logger.info(
            "Invoiced total(s) available for reconciliation: %s",
            "; ".join(f"{t['invoice_id']} {t['total']:,.2f} {chosen['currency']}"
                      for t in totals.values()),
        )
    else:
        logger.warning(
            "No TotalAmount on any invoice summary; rounding reconciliation skipped."
        )

    return (
        chosen["currency"],
        chosen["rate"],
        chosen["raw_rate"],
        provenance,
        list(totals.values()),
    )


def reconcile_to_invoice(breakdown, grand_total_usd, invoice_totals):
    """
    Absorb the sub-cent drift between Cost Explorer and the invoice.

    Cost Explorer reports unrounded amounts, while the invoice rounds every
    service line to the cent before summing them, so the two totals differ by a
    few cents spread across hundreds of line items -- there is no single line to
    attribute it to. Park the residual on RECONCILIATION_CBRID so the report
    ties exactly to the invoice.

    Returns a short description of the adjustment, or None if none was made.
    """
    if not invoice_totals or USD_TO_DISPLAY_RATE <= 0:
        return None

    computed = grand_total_usd * USD_TO_DISPLAY_RATE
    match = min(invoice_totals, key=lambda i: abs(i["total"] - computed))
    delta = match["total"] - computed

    if abs(delta) > RECONCILIATION_TOLERANCE:
        logger.warning(
            "Computed total %.2f %s is %.2f away from the nearest invoice (%s, %.2f), "
            "beyond the %.2f tolerance. Leaving the figures unreconciled -- a gap this "
            "large is a reporting error, not rounding.",
            computed, DISPLAY_CURRENCY_CODE, delta, match["invoice_id"],
            match["total"], RECONCILIATION_TOLERANCE,
        )
        return None

    delta_usd = round(delta / USD_TO_DISPLAY_RATE, 2)
    if not delta_usd:
        return None

    target = next(
        (e for e in breakdown if e["ssc_cbrid"] == RECONCILIATION_CBRID), None
    )
    if target is None:
        logger.warning(
            "No %s entry in the breakdown to absorb the %.2f %s rounding residual.",
            RECONCILIATION_CBRID, delta, DISPLAY_CURRENCY_CODE,
        )
        return None

    target["total"] = round(target["total"] + delta_usd, 2)
    # Keep account + resource costs summing to the row total.
    target["account_costs"] = round(target["account_costs"] + delta_usd, 2)

    note = (
        f"{delta:+,.2f} {DISPLAY_CURRENCY_CODE} rounding residual applied to "
        f"{RECONCILIATION_CBRID} to match {match['invoice_id']}"
    )
    logger.info("Reconciled to invoice: %s", note)
    return note


def get_costs_by_account_and_tag(start, end):
    """
    Returns {(account_id, tag_value): cost}, grouped by both linked account
    and ssc_cbrid resource tag. Empty tag_value means the resource is not
    tagged with ssc_cbrid (or the cost has no resource, e.g. taxes/support).
    """
    costs = {}
    groups_seen = 0
    pages = 0
    next_page_token = None

    while True:
        kwargs = {
            "Granularity": "MONTHLY",
            "TimePeriod": {"Start": start, "End": end},
            "Metrics": ["UnblendedCost"],
            "GroupBy": [
                {"Type": "TAG", "Key": TAG_KEY},
                {"Type": "DIMENSION", "Key": "LINKED_ACCOUNT"},
            ],
        }
        if next_page_token:
            kwargs["NextPageToken"] = next_page_token

        result = ce.get_cost_and_usage(**kwargs)
        pages += 1

        for period in result["ResultsByTime"]:
            for group in period["Groups"]:
                groups_seen += 1
                raw_tag, account_id = group["Keys"]
                tag_value = raw_tag.split("$", 1)[1] if "$" in raw_tag else raw_tag
                amount = float(group["Metrics"]["UnblendedCost"]["Amount"])
                key = (account_id, tag_value)
                costs[key] = costs.get(key, 0.0) + amount

        next_page_token = result.get("NextPageToken")
        if not next_page_token:
            break

    logger.info(
        "Cost Explorer returned %d group(s) over %d page(s); %d account/tag combination(s)",
        groups_seen, pages, len(costs),
    )
    return costs


def get_resources_for_tags(tag_values):
    """
    Returns {tag_value: [resource, ...]} by querying the audit account's Config
    aggregator. Each resource is {account_id, region, type, id, name, arn}.
    """
    if not CONFIG_READER_ROLE_ARN:
        logger.warning("CONFIG_READER_ROLE_ARN env var not set; skipping resource lookup")
        return {}
    if not CONFIG_AGGREGATOR_NAME:
        logger.warning("CONFIG_AGGREGATOR_NAME env var not set; skipping resource lookup")
        return {}
    if not tag_values:
        return {}

    sts = boto3.client("sts")
    creds = sts.assume_role(
        RoleArn=CONFIG_READER_ROLE_ARN,
        RoleSessionName="cost-report-config-reader",
    )["Credentials"]

    config = boto3.client(
        "config",
        region_name=CONFIG_AGGREGATOR_REGION,
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )

    results = {tag_value: [] for tag_value in tag_values}
    for tag_value in tag_values:
        expression = (
            f"SELECT accountId, awsRegion, resourceType, resourceId, resourceName, arn "
            f"WHERE tags.tag = '{TAG_KEY}={tag_value}'"
        )
        logger.info("Querying aggregator for tag %s=%s", TAG_KEY, tag_value)
        next_token = None
        while True:
            kwargs = {
                "Expression": expression,
                "ConfigurationAggregatorName": CONFIG_AGGREGATOR_NAME,
                "Limit": 100,
            }
            if next_token:
                kwargs["NextToken"] = next_token
            response = config.select_aggregate_resource_config(**kwargs)
            for raw in response.get("Results", []):
                row = json.loads(raw)
                results[tag_value].append({
                    "account_id": row.get("accountId", ""),
                    "region": row.get("awsRegion", ""),
                    "type": row.get("resourceType", ""),
                    "id": row.get("resourceId", ""),
                    "name": row.get("resourceName", "") or row.get("resourceId", ""),
                    "arn": row.get("arn", ""),
                })
            next_token = response.get("NextToken")
            if not next_token:
                break
        logger.info("Found %d resource(s) for %s=%s", len(results[tag_value]), TAG_KEY, tag_value)

    return results


def previous_month_range():
    today = date.today()
    if today.month == 1:
        start = date(today.year - 1, 12, 1)
    else:
        start = date(today.year, today.month - 1, 1)
    end = date(today.year, today.month, 1)
    label = start.strftime("%Y-%m")
    return start.isoformat(), end.isoformat(), label


def build_csv(report):
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow([
        "ssc_cbrid", "row_type", "account_id", "account_name",
        "resource_type", "resource_id", "resource_name", "region", "arn",
        "account_costs", "resource_costs", "total",
    ])
    for entry in report["breakdown"]:
        for account in entry["accounts"]:
            writer.writerow([
                entry["ssc_cbrid"], "account",
                account["id"], account["name"],
                "", "", "", "", "",
                f"{account['cost']:.2f}", "", "",
            ])
        for resource in entry.get("resources", []):
            writer.writerow([
                entry["ssc_cbrid"], "resource",
                resource["account_id"], "",
                resource["type"], resource["id"], resource["name"],
                resource["region"], resource["arn"],
                "", "", "",
            ])
        writer.writerow([
            entry["ssc_cbrid"], "tag_total",
            "", "", "", "", "", "", "",
            f"{entry['account_costs']:.2f}",
            f"{entry['resource_costs']:.2f}",
            f"{entry['total']:.2f}",
        ])
    writer.writerow([])
    writer.writerow([
        "", "grand_total", "", "", "", "", "", "", "",
        "", "", f"{report['grand_total']:.2f}",
    ])
    return buf.getvalue()


def build_doc(report):
    """
    Build a Word-compatible HTML document (saved with .doc extension).
    SharePoint previews this as Word and Outlook treats attachments as .doc.
    Tagged resources are omitted; only tag totals and per-account costs are
    included.
    """
    sections = "".join(
        build_html_section(entry, include_resources=False)
        for entry in report["breakdown"]
    )

    return f"""<html xmlns:o='urn:schemas-microsoft-com:office:office'
      xmlns:w='urn:schemas-microsoft-com:office:word'
      xmlns='http://www.w3.org/TR/REC-html40'>
<head>
<meta http-equiv="Content-Type" content="application/msword; charset=utf-8">
<title>AWS CBR Breakdown Monthly Cost Report - {escape(report["period"])}</title>
<xml>
<w:WordDocument>
  <w:View>Print</w:View>
  <w:Zoom>90</w:Zoom>
  <w:DoNotOptimizeForBrowser/>
</w:WordDocument>
</xml>
<style>
@page {{ size: letter portrait; margin: 0.75in; }}
body {{ font-family: Calibri, Arial, sans-serif; color: #222; }}
h1 {{ margin-bottom: 0.2em; }}
h2 {{ margin: 0; font-size: 1.2em; }}
.meta {{ color: #666; margin-bottom: 2em; }}
.num {{ text-align: right; white-space: nowrap; }}
.tag-block {{ border: 1px solid #e2e2e8; margin-bottom: 1.5em; }}
.tag-head {{
  display: flex; justify-content: space-between;
  padding: 8px 12px; background: #f0f3f7;
  border-bottom: 1px solid #e2e2e8;
}}
.tag-head .total {{ font-weight: bold; }}
.totals {{ padding: 8px 12px; color: #555; }}
table {{ border-collapse: collapse; width: 100%; }}
th, td {{ padding: 6px 12px; border-bottom: 1px solid #f0f0f0; text-align: left; }}
th {{ background: #fafbfc; font-size: 0.85em; color: #666; }}
.grand-total {{
  background: #e8f0fe; padding: 12px;
  display: flex; justify-content: space-between;
  font-weight: bold;
}}
</style>
</head>
<body>
<h1>AWS CBR Breakdown Monthly Cost Report</h1>
<p class="meta">Period: <strong>{escape(report["period"])}</strong> &middot; Generated: {escape(report["generated"])}</p>

{sections}

<div class="grand-total">
  <span>Grand Total</span>
  <span>{format_currency_with_cad(report["grand_total"])}</span>
</div>
<p style="font-size:0.75em; color:#999; text-align:right; margin-top:1em;">Exchange rate: 1 USD = {DISPLAY_RATE_TEXT} {DISPLAY_CURRENCY_CODE} ({RATE_SOURCE}) &nbsp;&middot;&nbsp; Pre-tax excludes {TAX_RATE*100:.0f}% HST{reconciliation_note(report)} &nbsp;&middot;&nbsp; Savings plan discount: {SAVINGS_PLAN_RATE*100:.2f}%</p>
</body>
</html>
"""


def send_email_with_doc(report, doc_bytes, label):
    recipients = [e.strip() for e in RECIPIENT_EMAILS.split(",") if e.strip()]
    if not recipients:
        logger.warning("No valid recipient emails; skipping email")
        return

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"AWS CBR Breakdown Monthly Cost Report - {report['period']}"
    msg["From"] = SENDER_EMAIL
    msg["To"] = ", ".join(recipients)

    grand_cad = report["grand_total"] * USD_TO_DISPLAY_RATE
    grand_pre_tax = grand_cad / (1 + TAX_RATE)

    # Plain-text fallback
    breakdown_lines = []
    for entry in report["breakdown"]:
        po = COST_REPORT_PO_NUMBERS.get(entry["ssc_cbrid"])
        po_str = f" (PO {po})" if po else ""
        cad = entry["total"] * USD_TO_DISPLAY_RATE
        pre_tax = cad / (1 + TAX_RATE)
        breakdown_lines.append(
            f"  {entry['ssc_cbrid']}{po_str}: "
            f"${pre_tax:,.2f} {DISPLAY_CURRENCY_CODE} pre-tax "
            f"(incl. tax: ${cad:,.2f} {DISPLAY_CURRENCY_CODE} / {format_currency(entry['total'])})"
        )
    breakdown_text = "\n".join(breakdown_lines)

    plain_body = (
        f"AWS CBR Breakdown Monthly Cost Report\n"
        f"Period: {report['period']}\n"
        f"Generated: {report['generated']}\n"
        f"\n"
        f"{'='*50}\n"
        f"BREAKDOWN BY CBR ID\n"
        f"{'='*50}\n"
        f"{breakdown_text}\n"
        f"\n"
        f"{'='*50}\n"
        f"GRAND TOTAL (pre-tax): ${grand_pre_tax:,.2f} {DISPLAY_CURRENCY_CODE}\n"
        f"GRAND TOTAL (incl. tax): ${grand_cad:,.2f} {DISPLAY_CURRENCY_CODE} / {format_currency(report['grand_total'])}\n"
        f"{'='*50}\n"
        f"\n"
        f"Exchange rate: 1 USD = {DISPLAY_RATE_TEXT} {DISPLAY_CURRENCY_CODE} ({RATE_SOURCE})\n"
        f"Amounts include {TAX_RATE*100:.0f}% HST; pre-tax amounts shown separately.\n"
        f"\n"
        f"The full report is attached as a Word document."
    )
    msg.attach(MIMEText(plain_body, "plain"))

    # HTML body
    breakdown_rows = ""
    for entry in report["breakdown"]:
        po = COST_REPORT_PO_NUMBERS.get(entry["ssc_cbrid"])
        po_cell = f'<span style="font-size:0.85em;color:#666;">(PO {escape(po)})</span>' if po else ""
        cad = entry["total"] * USD_TO_DISPLAY_RATE
        pre_tax = cad / (1 + TAX_RATE)
        breakdown_rows += (
            f'<tr>'
            f'<td style="padding:8px 12px;border-bottom:1px solid #eee;">'
            f'<strong>{escape(entry["ssc_cbrid"])}</strong> {po_cell}</td>'
            f'<td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:right;font-weight:bold;color:#1a3a5c;">'
            f'${pre_tax:,.2f} {DISPLAY_CURRENCY_CODE}</td>'
            f'<td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:right;font-weight:600;color:#555;font-size:0.9em;">'
            f'${cad:,.2f} {DISPLAY_CURRENCY_CODE}</td>'
            f'<td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:right;color:#666;font-size:0.9em;">'
            f'{format_currency(entry["total"])}</td>'
            f'</tr>'
        )

    html_body = f"""<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f9;padding:32px 0;">
    <tr><td align="center">
      <table width="620" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">

        <!-- Header -->
        <tr>
          <td style="background:#1a3a5c;padding:28px 32px;">
            <h1 style="margin:0;color:#fff;font-size:1.3em;font-weight:600;">AWS CBR Breakdown Monthly Cost Report</h1>
            <p style="margin:6px 0 0;color:#a8c4e0;font-size:0.9em;">
              Period: <strong>{escape(report["period"])}</strong> &nbsp;&middot;&nbsp; Generated: {escape(report["generated"])}
            </p>
          </td>
        </tr>

        <!-- Grand total banner -->
        <tr>
          <td style="background:#e8f0fe;padding:20px 32px;border-bottom:1px solid #d0ddf5;">
            <p style="margin:0;font-size:0.85em;color:#555;text-transform:uppercase;letter-spacing:0.05em;">Grand Total (pre-tax)</p>
                        <p style="margin:4px 0 0;font-size:2.4em;font-weight:800;color:#1a3a5c;">${grand_pre_tax:,.2f} {DISPLAY_CURRENCY_CODE}</p>
            <p style="margin:2px 0 0;font-size:0.95em;color:#666;">Incl. tax: ${grand_cad:,.2f} {DISPLAY_CURRENCY_CODE} &middot; {format_currency(report["grand_total"])}</p>
          </td>
        </tr>

        <!-- Breakdown table -->
        <tr>
          <td style="padding:24px 32px 8px;">
            <p style="margin:0 0 12px;font-weight:600;color:#333;font-size:1em;">Breakdown by CBR ID</p>
            <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;font-size:0.93em;">
              <thead>
                <tr style="background:#f4f6f9;">
                  <th style="padding:8px 12px;text-align:left;color:#666;font-size:0.8em;text-transform:uppercase;letter-spacing:0.04em;border-bottom:2px solid #e2e2e8;">CBR ID</th>
                  <th style="padding:8px 12px;text-align:right;color:#666;font-size:0.8em;text-transform:uppercase;letter-spacing:0.04em;border-bottom:2px solid #e2e2e8;">Pre-tax ({DISPLAY_CURRENCY_CODE})</th>
                                    <th style="padding:8px 12px;text-align:right;color:#666;font-size:0.8em;text-transform:uppercase;letter-spacing:0.04em;border-bottom:2px solid #e2e2e8;">Incl. tax ({DISPLAY_CURRENCY_CODE})</th>
                  <th style="padding:8px 12px;text-align:right;color:#666;font-size:0.8em;text-transform:uppercase;letter-spacing:0.04em;border-bottom:2px solid #e2e2e8;">Incl. tax (USD)</th>
                </tr>
              </thead>
              <tbody>
                {breakdown_rows}
              </tbody>
            </table>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="padding:20px 32px 28px;">
            <p style="margin:0;font-size:0.85em;color:#888;">
              The full report with account-level details is attached as a Word document.
            </p>
            <p style="margin:8px 0 0;font-size:0.78em;color:#aaa;">
                            Exchange rate: 1 USD = {DISPLAY_RATE_TEXT} {DISPLAY_CURRENCY_CODE} ({RATE_SOURCE}) &nbsp;&middot;&nbsp; Incl.-tax amounts contain {TAX_RATE*100:.0f}% HST
            </p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>"""

    msg.attach(MIMEText(html_body, "html"))

    # Attach the Word doc as a separate part
    outer = MIMEMultipart("mixed")
    outer["Subject"] = msg["Subject"]
    outer["From"] = msg["From"]
    outer["To"] = msg["To"]
    outer["Cc"] = SENDER_EMAIL
    outer.attach(msg)

    attachment = MIMEApplication(doc_bytes, _subtype="msword")
    attachment.add_header("Content-Disposition", "attachment", filename=f"cost-report-{label}.doc")
    outer.attach(attachment)

    ses.send_raw_email(
        Source=SENDER_EMAIL,
        Destinations=recipients + [SENDER_EMAIL],
        RawMessage={"Data": outer.as_bytes()},
    )
    logger.info("Email sent to %s", recipients)


def build_html(report):
    sections = [build_html_section(entry) for entry in report["breakdown"]]

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>AWS CBR Breakdown Monthly Cost Report - {escape(report["period"])}</title>
<style>
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    margin: 2em auto; max-width: 1100px; color: #222; background: #f7f7f9;
  }}
  h1 {{ margin-bottom: 0.2em; }}
  h2 {{ margin: 0; font-size: 1.2em; }}
  .meta {{ color: #666; margin-bottom: 2em; }}
  .num {{ text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }}
  code {{ background: #eef; padding: 1px 5px; border-radius: 3px; font-size: 0.85em; }}

  .tag-block {{
    background: #fff; border: 1px solid #e2e2e8; border-radius: 6px;
    margin-bottom: 1.5em; overflow: hidden;
  }}
  .tag-head {{
    display: flex; align-items: center; justify-content: space-between;
    padding: 12px 16px; background: #f0f3f7; border-bottom: 1px solid #e2e2e8;
  }}
  .tag-head .total {{ font-size: 1.15em; font-weight: bold; }}
  .totals {{ display: flex; gap: 2em; padding: 10px 16px; color: #555; font-size: 0.92em; }}
  .totals strong {{ color: #222; }}

  table {{ border-collapse: collapse; width: 100%; table-layout: fixed; }}
  th, td {{ padding: 7px 16px; border-bottom: 1px solid #f0f0f0; text-align: left; vertical-align: top; }}
  th {{ background: #fafbfc; font-size: 0.82em; text-transform: uppercase; color: #666; letter-spacing: 0.04em; }}

  .accounts-table td.name {{ font-size: 0.94em; }}
  .accounts-table td.id {{ color: #888; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.85em; }}

  details {{ border-top: 1px solid #eee; }}
  summary {{
    padding: 12px 16px; cursor: pointer; user-select: none;
    background: #eef2f7; color: #1d4ed8; font-weight: 600; font-size: 0.95em;
    list-style: none; display: flex; align-items: center; gap: 8px;
    border-bottom: 1px solid #d0d7e2;
  }}
  summary::-webkit-details-marker {{ display: none; }}
  summary:hover {{ background: #dbe5f1; }}
  summary .chevron {{
    display: inline-block; transition: transform 0.15s ease;
    font-size: 0.9em; color: #1d4ed8;
  }}
  details[open] summary .chevron {{ transform: rotate(90deg); }}
  details[open] summary {{ background: #dbe5f1; }}

  .resources-table {{ font-size: 0.88em; }}
  .resources-table th {{ background: #fafbfc; }}
  .resources-table td {{ word-break: break-word; overflow-wrap: anywhere; }}
  .resources-table .type {{ width: 22%; }}
  .resources-table .name {{ width: 42%; }}
  .resources-table .acct {{ width: 18%; }}
  .resources-table .region {{ width: 18%; }}
  .badge {{
    display: inline-block; background: #eef0f3; color: #345;
    padding: 1px 6px; border-radius: 3px; font-size: 0.85em;
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  }}
  .arn {{ color: #999; font-size: 0.8em; word-break: break-all; }}

  .grand-total {{
    background: #e8f0fe; padding: 14px 16px; border-radius: 6px;
    display: flex; justify-content: space-between; font-weight: bold; font-size: 1.1em;
  }}
</style>
</head>
<body>
<h1>AWS CBR Breakdown Monthly Cost Report</h1>
<p class="meta">Period: <strong>{escape(report["period"])}</strong> &middot; Generated: {escape(report["generated"])}</p>

{''.join(sections)}

<div class="grand-total">
  <span>Grand Total</span>
  <span>{format_currency_with_cad(report["grand_total"])}</span>
</div>
<p style="font-size:0.75em; color:#999; text-align:right; margin-top:1em;">Exchange rate: 1 USD = {DISPLAY_RATE_TEXT} {DISPLAY_CURRENCY_CODE} ({RATE_SOURCE}) &nbsp;&middot;&nbsp; Pre-tax excludes {TAX_RATE*100:.0f}% HST{reconciliation_note(report)} &nbsp;&middot;&nbsp; Savings plan discount: {SAVINGS_PLAN_RATE*100:.2f}%</p>
</body>
</html>
"""


def build_html_section(entry, include_resources=True):
    account_rows = "".join(
        f'<tr>'
        f'<td class="name">{escape(account["name"])}</td>'
        f'<td class="id">{escape(account["id"])}</td>'
        f'<td class="num">{format_currency(account["cost"])}</td>'
        f'</tr>'
        for account in entry["accounts"]
    )

    resources = entry.get("resources", []) if include_resources else []
    resource_section = ""
    if resources:
        resource_rows = "".join(
            f'<tr>'
            f'<td class="type"><span class="badge">{escape(short_resource_type(r["type"]))}</span></td>'
            f'<td class="name">'
            f'<div>{escape(r["name"])}</div>'
            + (f'<div class="arn">{escape(r["arn"] or r["id"])}</div>' if (r["arn"] or r["id"]) != r["name"] else "")
            + f'</td>'
            f'<td class="acct">{escape(r["account_id"])}</td>'
            f'<td class="region">{escape(r["region"])}</td>'
            f'</tr>'
            for r in resources
        )
        resource_section = f"""
<details>
  <summary>
    <span class="chevron">&#9656;</span>
    <span class="summary-text">Show {len(resources)} tagged resource(s)</span>
  </summary>
  <table class="resources-table">
    <thead>
      <tr>
        <th class="type">Type</th>
        <th class="name">Name / Identifier</th>
        <th class="acct">Account</th>
        <th class="region">Region</th>
      </tr>
    </thead>
    <tbody>{resource_rows}</tbody>
  </table>
</details>
"""

    accounts_table = ""
    if entry["accounts"]:
        accounts_table = f"""
<table class="accounts-table">
  <thead>
    <tr>
      <th>Account Name</th>
      <th>Account ID</th>
      <th class="num">Account-tagged Cost</th>
    </tr>
  </thead>
  <tbody>{account_rows}</tbody>
</table>
"""

    cbrid = entry["ssc_cbrid"]
    po = COST_REPORT_PO_NUMBERS.get(cbrid)
    po_label = f' <span style="font-size:0.8em; color:#667; font-weight:normal;">(PO {escape(po)})</span>' if po else ""

    return f"""
<section class="tag-block">
  <div class="tag-head">
    <h2>{escape(cbrid)}{po_label}</h2>
    <span class="total">{format_currency_with_cad(entry["total"])}</span>
  </div>
  <div class="totals">
    <div>Account-tagged: <strong>{format_currency_with_cad(entry["account_costs"], show_pretax=False)}</strong></div>
    <div>Resource-tagged: <strong>{format_currency_with_cad(entry["resource_costs"], show_pretax=False)}</strong></div>
  </div>
  {accounts_table}
  {resource_section}
</section>
"""


def reconciliation_note(report):
    """Footer fragment naming the rounding residual, when one was applied."""
    note = report.get("reconciliation")
    return f" &nbsp;&middot;&nbsp; {escape(note)}" if note else ""


def short_resource_type(resource_type):
    return resource_type.replace("AWS::", "") if resource_type else "Unknown"


def format_currency_cad(amount):
    return f"${amount * USD_TO_DISPLAY_RATE:,.2f} {DISPLAY_CURRENCY_CODE}"


def build_slack_message(report, html_url=None):
    blocks = [
        {"type": "header", "text": {"type": "plain_text", "text": f"AWS CBR Breakdown Monthly Cost Report - {report['period']}"}},
        {"type": "divider"},
        {"type": "section", "text": {"type": "mrkdwn", "text": "*Breakdown by ssc_cbrid:*"}},
    ]

    for entry in report["breakdown"]:
        blocks.append({
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*{entry['ssc_cbrid']}*"},
                {"type": "mrkdwn", "text": format_currency_cad(entry["total"])},
                {"type": "mrkdwn", "text": f"_Account-tagged:_ {format_currency_cad(entry['account_costs'])}"},
                {"type": "mrkdwn", "text": f"_Resource-tagged:_ {format_currency_cad(entry['resource_costs'])}"},
            ],
        })

    blocks.extend([
        {"type": "divider"},
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": "*Grand Total*"},
                {"type": "mrkdwn", "text": format_currency_cad(report["grand_total"])},
            ],
        },
    ])

    if html_url:
        blocks.extend([
            {"type": "divider"},
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Download full report:* <{html_url}|View HTML report>",
                },
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": "You must be logged into the *org management account* "
                                "in the AWS Console to open this link.",
                    }
                ],
            },
        ])

    return {"blocks": blocks}


def s3_console_url(bucket, key):
    region = os.getenv("AWS_REGION", "ca-central-1")
    return (
        f"https://{region}.console.aws.amazon.com/s3/object/{bucket}"
        f"?region={region}&prefix={key}"
    )


def format_currency(amount):
    return f"${amount:,.2f} USD"


def format_currency_with_cad(amount, show_pretax=True):
    cad = amount * USD_TO_DISPLAY_RATE
    if not show_pretax:
        return (
            f'<span style="font-size:1.1em; font-weight:bold;">${cad:,.2f} {DISPLAY_CURRENCY_CODE}</span>'
            f'&nbsp;<span style="font-size:0.75em; color:#777; font-weight:normal;">${amount:,.2f} USD</span>'
        )
    pre_tax = cad / (1 + TAX_RATE)
    return (
        f'<span style="display:inline-block; text-align:right; line-height:1.3;">'
        f'<span style="font-size:1.05em; font-weight:bold; display:block;">'
        f'${pre_tax:,.2f} {DISPLAY_CURRENCY_CODE}'
        f' <span style="font-size:0.75em; color:#777; font-weight:normal;">pre-tax</span></span>'
        f'<span style="font-size:0.8em; color:#555; font-weight:normal;">'
        f'${cad:,.2f} {DISPLAY_CURRENCY_CODE} &middot; ${amount:,.2f} USD'
        f' <span style="color:#999;">incl. tax</span></span>'
        f'</span>'
    )


def post_to_slack(webhook_url, message):
    parsed = urlparse(webhook_url)
    path = parsed.path + (f"?{parsed.query}" if parsed.query else "")
    body = json.dumps(message)
    conn = HTTPSConnection(parsed.hostname, parsed.port or 443)
    conn.request(
        "POST",
        path,
        body=body,
        headers={
            "Content-Type": "application/json",
            "Content-Length": str(len(body)),
            "User-Agent": "AWS_Lambda_Cost_Report (Python)",
        },
    )
    response = conn.getresponse()
    logger.info("Slack response: %s %s", response.status, response.read().decode())
    conn.close()
