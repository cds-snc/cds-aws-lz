
resource "aws_guardduty_detector" "ca_central_1" {

  provider = aws.ca_central_1

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      enable = true
    }
  }
}

resource "aws_guardduty_detector" "us_east_1" {
  provider = aws.us_east_1

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      enable = true
    }
  }
}

resource "aws_guardduty_detector" "us_west_2" {

  provider = aws.us_west_2

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  # Additional setting to turn on S3 Protection
  datasources {
    s3_logs {
      enable = true
    }
  }
}

output "ca_central_1_detector_id" {
  value = aws_guardduty_detector.ca_central_1.id
}

output "us_east_1_detector_id" {
  value = aws_guardduty_detector.us_east_1.id
}

output "us_west_2_detector_id" {
  value = aws_guardduty_detector.us_west_2.id
}