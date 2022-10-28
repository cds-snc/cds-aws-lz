resource "aws_sqs_queue" "cloudtrail_sqs_queue" {
  provider = aws.log_archive

  name                      = "azure-sentinel-cloudtrail-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

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
      "Sid": "CloudTrailSQS",
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
      values   = [var.lw_customer_id]
    }
  }
}

resource "aws_iam_role" "azure_sentinel" {
  provider = aws.log_archive

  name               = "AzureSentinelRole"
  description        = "Azure Sentinel Integration"
  assume_role_policy = data.aws_iam_policy_document.azure_sentinel_assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]
}
