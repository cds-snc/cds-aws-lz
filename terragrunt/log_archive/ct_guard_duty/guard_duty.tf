data "aws_guardduty_detector" "guard_duty" { }

resource "aws_guardduty_publishing_destination" "cds_sentinel_guard_duty_destination" {
  detector_id     = data.aws_guardduty_detector.guard_duty.id
  destination_arn = module.guard_duty.s3_bucket_arn
  kms_key_arn     = aws_kms_key.cds_sentinel_guard_duty_key.arn

  depends_on = [
    aws_s3_bucket_policy.cds_sentinel_guard_duty_policy,
  ]
}