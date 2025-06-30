# EventBridge Rule for Cloud Brokering Role Monitoring
resource "aws_cloudwatch_event_rule" "cloud_brokering_monitoring" {
  name        = "cloud-brokering-iam-monitoring"
  description = "Monitor IAM actions performed by Cloud Brokering role"
  state       = "ENABLED"

  event_pattern = jsonencode({
    detail = {
      eventName = [
        "DeleteRolePolicy",
        "AttachRolePolicy",
        "DeleteRole",
        "DetachRolePolicy",
        "PutRolePolicy",
        "UpdateAssumeRolePolicy"
      ]
      eventSource = ["iam.amazonaws.com"]
      userIdentity = {
        sessionContext = {
          sessionIssuer = {
            type = ["Role"]
            arn  = [var.cloud_brokering_role_arn]
          }
        }
      }
    }
    detail-type = ["AWS API Call via CloudTrail"]
    source      = ["aws.iam"]
  })
}

# EventBridge Target - SNS Topic
resource "aws_cloudwatch_event_target" "cloud_brokering_sns_target" {
  rule      = aws_cloudwatch_event_rule.cloud_brokering_monitoring.name
  target_id = "CloudBrokeringSNSTarget"
  arn       = aws_sns_topic.cloud_brokering_alerts.arn

  # Input transformer to format the alert message
  input_transformer {
    input_paths = {
      eventName        = "$.detail.eventName"
      eventTime        = "$.detail.eventTime"
      eventId          = "$.detail.eventId"
      sourceIPAddress  = "$.detail.sourceIPAddress"
      userArn          = "$.detail.userIdentity.arn"
      sessionIssuerArn = "$.detail.userIdentity.sessionContext.sessionIssuer.arn"
      awsRegion        = "$.detail.awsRegion"
    }

    input_template = jsonencode({
      alert_type      = "CLOUD_BROKERING_SECURITY_EVENT"
      severity        = "HIGH"
      event_name      = "<eventName>"
      event_time      = "<eventTime>"
      event_id        = "<eventId>"
      source_ip       = "<sourceIPAddress>"
      user_arn        = "<userArn>"
      role_arn        = "<sessionIssuerArn>"
      region          = "<awsRegion>"
      message         = "🚨 SECURITY ALERT: Cloud Brokering role performed IAM action '<eventName>' at <eventTime> from IP <sourceIPAddress>"
      action_required = "Investigate this activity immediately to ensure it was authorized"
    })
  }
}