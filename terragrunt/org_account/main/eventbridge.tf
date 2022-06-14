resource "aws_cloudwatch_event_rule" "cds_sentinel_securityhub_rule" {
  provider    = aws.log_archive
  name        = "cds-sentinel-securityhub-rule"
  description = "Capture security hub events"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.securityhub"
  ],
  "detail-type": [
    "Security Hub Findings - Imported"
  ],
  "detail": {
    "findings": {
      "Severity": [
        "CRITICAL", "HIGH", "MEDIUM", "LOW"
      ]
    }
  }
}
PATTERN
}