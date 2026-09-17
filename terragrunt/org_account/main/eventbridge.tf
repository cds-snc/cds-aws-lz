resource "aws_cloudwatch_event_rule" "cds_sentinel_securityhub_rule" {
  provider    = aws.log_archive
  name        = "cds-sentinel-securityhub-rule"
  description = "Capture security hub events"

  # Severity is an ASFF object — {Label, Normalized, Original} — not a string, so
  # matching an array of strings against it can never match and this rule has
  # fired zero times since it was created. The severity lives at Severity.Label.
  #
  # Measured 2026-09-17: 0 invocations of sentinel-securityhub-forwarder in 90
  # days, while this account is the Security Hub delegated administrator with a
  # finding aggregator and 50 member accounts feeding it continuously.
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
      "Severity": {
        "Label": [
          "CRITICAL", "HIGH", "MEDIUM", "LOW"
        ]
      }
    }
  }
}
PATTERN
}