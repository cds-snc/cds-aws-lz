resource "aws_sqs_queue" "cloudtrail_sqs_queue" {
  provider = aws.log_archive

  name                      = "azure-sentinel-cloudtrail-queue"
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 5
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "guardduty_queue" {
  provider = aws.log_archive

  name                      = "azure-sentinel-guardduty-queue"
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 5
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  provider = aws.log_archive

  queue_url = aws_sqs_queue.cloudtrail_sqs_queue.id
  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "SentinelSQS",
      "Effect": "Allow",
      "Principal": {
          "Service": "s3.amazonaws.com"
      },
      "Action": [
          "SQS:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.cloudtrail_sqs_queue.arn}",
      "Condition": {
          "ArnLike": {
              "aws:SourceArn": "arn:aws:s3:::aws-controltower-logs-${data.aws_caller_identity.log_archive.account_id}-${var.region}"
          },
          "StringEquals": {
              "aws:SourceAccount": "${data.aws_caller_identity.log_archive.account_id}"
          }
      }
    },
    {
      "Sid": "CloudTrailSQS",
      "Effect": "Allow",
      "Principal": {
           "AWS": "arn:aws:iam::${data.aws_caller_identity.log_archive.account_id}:role/AzureSentinelRole"
      },
      "Action": [
        "SQS:ChangeMessageVisibility",
        "SQS:DeleteMessage",
        "SQS:ReceiveMessage",
        "SQS:GetQueueUrl"
      ],
      "Resource": "${aws_sqs_queue.cloudtrail_sqs_queue.arn}"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "azure_cloudtrail_bucket_notification" {
  provider = aws.log_archive

  bucket = "aws-controltower-logs-${data.aws_caller_identity.log_archive.account_id}-${var.region}"
  queue {
    id            = "azure-sentinel-cloudtrail-queue-log-event"
    queue_arn     = aws_sqs_queue.cloudtrail_sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "o-625no8z3dd/AWSLogs/o-625no8z3dd"
  }
  depends_on = [
    aws_sqs_queue.cloudtrail_sqs_queue
  ]
}

# GuardDuty findings are published to module.publishing_bucket (see guardduty.tf).
# Wire that bucket's ObjectCreated events to the dedicated GuardDuty SQS queue so
# the Sentinel S3 connector can pick them up (a single queue may only serve one
# log type/path, per https://learn.microsoft.com/en-us/azure/sentinel/connect-aws).
resource "aws_sqs_queue_policy" "guardduty_sqs_queue_policy" {
  provider = aws.log_archive

  queue_url = aws_sqs_queue.guardduty_queue.id
  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "SentinelSQS",
      "Effect": "Allow",
      "Principal": {
          "Service": "s3.amazonaws.com"
      },
      "Action": [
          "SQS:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.guardduty_queue.arn}",
      "Condition": {
          "ArnLike": {
              "aws:SourceArn": "${module.publishing_bucket.s3_bucket_arn}"
          },
          "StringEquals": {
              "aws:SourceAccount": "${data.aws_caller_identity.log_archive.account_id}"
          }
      }
    },
    {
      "Sid": "GuardDutySQS",
      "Effect": "Allow",
      "Principal": {
           "AWS": "${aws_iam_role.azure_sentinel.arn}"
      },
      "Action": [
        "SQS:ChangeMessageVisibility",
        "SQS:DeleteMessage",
        "SQS:ReceiveMessage",
        "SQS:GetQueueUrl"
      ],
      "Resource": "${aws_sqs_queue.guardduty_queue.arn}"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "azure_guardduty_bucket_notification" {
  provider = aws.log_archive

  bucket = module.publishing_bucket.s3_bucket_id
  queue {
    id            = "azure-sentinel-guardduty-queue-log-event"
    queue_arn     = aws_sqs_queue.guardduty_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "AWSLogs/"
  }
  depends_on = [
    aws_sqs_queue.guardduty_queue,
    aws_sqs_queue_policy.guardduty_sqs_queue_policy
  ]
}

data "aws_iam_policy_document" "azure_sentinel_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::197857026523:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = var.lw_customer_ids
    }
  }
}

resource "aws_iam_role" "azure_sentinel" {
  provider = aws.log_archive

  name               = "AzureSentinelRole"
  description        = "Azure Sentinel Integration"
  assume_role_policy = data.aws_iam_policy_document.azure_sentinel_assume_role.json
}

# managed_policy_arns on the role above would be authoritative for the role's entire
# set of managed policy attachments, so it would detach anything attached by an
# aws_iam_role_policy_attachment resource (see azure_sentinel_guardduty_kms below) on
# every apply. All attachments are therefore expressed as attachment resources.
resource "aws_iam_role_policy_attachment" "azure_sentinel" {
  provider = aws.log_archive

  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ])

  role       = aws_iam_role.azure_sentinel.name
  policy_arn = each.value
}

# GuardDuty findings in module.publishing_bucket are encrypted with a customer-managed
# KMS key (aws_kms_key.cds_sentinel_guard_duty_key in guardduty.tf), so the Sentinel
# role needs explicit decrypt permission to read those objects.
data "aws_iam_policy_document" "azure_sentinel_guardduty_kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.cds_sentinel_guard_duty_key.arn]
  }
}

resource "aws_iam_policy" "azure_sentinel_guardduty_kms" {
  provider = aws.log_archive

  name   = "azure-sentinel-guardduty-kms-decrypt"
  policy = data.aws_iam_policy_document.azure_sentinel_guardduty_kms.json
}

resource "aws_iam_role_policy_attachment" "azure_sentinel_guardduty_kms" {
  provider = aws.log_archive

  role       = aws_iam_role.azure_sentinel.name
  policy_arn = aws_iam_policy.azure_sentinel_guardduty_kms.arn
}
