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
  arn       = aws_sns_topic.guardrail_alerts.arn

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


# EventBridge Rule for KMS Key Monitoring and access changes
resource "aws_cloudwatch_event_rule" "guardrails_kms_monitoring" {
  name        = "guardrails-kms-monitoring"
  description = "Monitor KMS key usage and access changes"
  state       = "ENABLED"

  event_pattern = jsonencode({
    source      = ["aws.kms"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "CreateKey",
        "ScheduleKeyDeletion",
        "CancelKeyDeletion",
        "DisableKey",
        "EnableKey",
        "PutKeyPolicy",
        "UpdateKeyDescription"
      ]
    }
  })
}

# EventBridge Target - SNS Topic
resource "aws_cloudwatch_event_target" "guardrails_kms_sns_target" {
  rule      = aws_cloudwatch_event_rule.guardrails_kms_monitoring.name
  target_id = "GuardrailsKMSSNSTarget"
  arn       = aws_sns_topic.guardrail_alerts.arn

  # Input transformer to format the alert message
  # Input transformer to format the alert message
  input_transformer {
    input_paths = {
      eventName       = "$.detail.eventName"
      eventTime       = "$.detail.eventTime"
      eventId         = "$.detail.eventId"
      sourceIPAddress = "$.detail.sourceIPAddress"
      userArn         = "$.detail.userIdentity.arn"
      awsRegion       = "$.detail.awsRegion"
      keyId           = "$.detail.responseElements.keyMetadata.keyId"
      keyArn          = "$.detail.responseElements.keyMetadata.arn"
    }

    input_template = jsonencode({
      alert_type      = "KMS_SECURITY_EVENT"
      severity        = "HIGH"
      event_name      = "<eventName>"
      event_time      = "<eventTime>"
      event_id        = "<eventId>"
      source_ip       = "<sourceIPAddress>"
      user_arn        = "<userArn>"
      region          = "<awsRegion>"
      kms_key_id      = "<keyId>"
      kms_key_arn     = "<keyArn>"
      message         = "🔐 KMS ALERT: '<eventName>' performed on KMS key at <eventTime> by <userArn> from IP <sourceIPAddress>"
      action_required = "Review this KMS activity to ensure it was authorized"
    })
  }
}

# EventBridge Rule for IAM AdministratorAccess Policy Detachment Monitoring
resource "aws_cloudwatch_event_rule" "guardrails_iam_admin_policy_monitoring_demotion" {
  name        = "guardrails-iam-admin-policy-monitoring-demotion"
  description = "Monitor IAM AdministratorAccess policy detachment events"
  state       = "ENABLED"

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "DetachUserPolicy",
        "DetachGroupPolicy",
        "DetachRolePolicy"
      ]
      requestParameters = {
        policyArn = [{
          suffix = "policy/AdministratorAccess"
        }]
      }
    }
  })
}

# EventBridge Target - SNS Topic
resource "aws_cloudwatch_event_target" "guardrails_iam_admin_demotion_policy_sns_target" {
  rule      = aws_cloudwatch_event_rule.guardrails_iam_admin_policy_monitoring_demotion.name
  target_id = "GuardrailsIAMAdminPolicySNSTarget"
  arn       = aws_sns_topic.guardrail_alerts.arn

  # Input transformer to format the alert message
  input_transformer {
    input_paths = {
      eventName       = "$.detail.eventName"
      eventTime       = "$.detail.eventTime"
      eventId         = "$.detail.eventId"
      sourceIPAddress = "$.detail.sourceIPAddress"
      userArn         = "$.detail.userIdentity.arn"
      awsRegion       = "$.detail.awsRegion"
      policyArn       = "$.detail.requestParameters.policyArn"
      targetUser      = "$.detail.requestParameters.userName"
      targetGroup     = "$.detail.requestParameters.groupName"
      targetRole      = "$.detail.requestParameters.roleName"
    }

    input_template = jsonencode({
      alert_type      = "IAM_ADMIN_POLICY_DETACHMENT"
      severity        = "CRITICAL"
      event_name      = "<eventName>"
      event_time      = "<eventTime>"
      event_id        = "<eventId>"
      source_ip       = "<sourceIPAddress>"
      user_arn        = "<userArn>"
      region          = "<awsRegion>"
      policy_arn      = "<policyArn>"
      target_user     = "<targetUser>"
      target_group    = "<targetGroup>"
      target_role     = "<targetRole>"
      message         = "🚨 CRITICAL IAM ALERT: AdministratorAccess policy detached via '<eventName>' at <eventTime> by <userArn> from IP <sourceIPAddress>"
      action_required = "IMMEDIATE REVIEW REQUIRED: AdministratorAccess policy has been detached - verify this was authorized"
    })
  }
}

# EventBridge Rule for AWS Secrets Manager Monitoring
resource "aws_cloudwatch_event_rule" "guardrails_secrets_manager_monitoring" {
  name        = "guardrails-secrets-manager-monitoring"
  description = "Monitor AWS Secrets Manager operations"
  state       = "ENABLED"

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "CreateSecret",
        "UpdateSecret",
        "PutSecretValue",
        "DeleteSecret",
        "RestoreSecret",
        "RotateSecret"
      ]
    }
  })
}

# EventBridge Target - SNS Topic
resource "aws_cloudwatch_event_target" "guardrails_secrets_manager_sns_target" {
  rule      = aws_cloudwatch_event_rule.guardrails_secrets_manager_monitoring.name
  target_id = "GuardrailsSecretsManagerSNSTarget"
  arn       = aws_sns_topic.guardrail_alerts.arn

  # Input transformer to format the alert message
  input_transformer {
    input_paths = {
      eventName       = "$.detail.eventName"
      eventTime       = "$.detail.eventTime"
      eventId         = "$.detail.eventId"
      sourceIPAddress = "$.detail.sourceIPAddress"
      userArn         = "$.detail.userIdentity.arn"
      awsRegion       = "$.detail.awsRegion"
      secretName      = "$.detail.requestParameters.name"
      secretArn       = "$.detail.responseElements.arn"
      secretId        = "$.detail.responseElements.versionId"
    }

    input_template = jsonencode({
      alert_type      = "SECRETS_MANAGER_SECURITY_EVENT"
      severity        = "HIGH"
      event_name      = "<eventName>"
      event_time      = "<eventTime>"
      event_id        = "<eventId>"
      source_ip       = "<sourceIPAddress>"
      user_arn        = "<userArn>"
      region          = "<awsRegion>"
      secret_name     = "<secretName>"
      secret_arn      = "<secretArn>"
      secret_id       = "<secretId>"
      message         = "🔐 SECRETS MANAGER ALERT: '<eventName>' performed on secret at <eventTime> by <userArn> from IP <sourceIPAddress>"
      action_required = "Review this Secrets Manager activity to ensure it was authorized and follows security protocols"
    })
  }
}

# EventBridge Rule for IAM AdministratorAccess Policy Attachment Monitoring
resource "aws_cloudwatch_event_rule" "guardrails_iam_admin_policy_monitoring_promotion" {
  name        = "guardrails-iam-admin-policy-monitoring-promotion"
  description = "Monitor IAM AdministratorAccess policy attachment events"
  state       = "ENABLED"

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "AttachUserPolicy",
        "AttachGroupPolicy",
        "AttachRolePolicy"
      ]
      requestParameters = {
        policyArn = [{
          suffix = "policy/AdministratorAccess"
        }]
      }
    }
  })
}

# EventBridge Target - SNS Topic
resource "aws_cloudwatch_event_target" "guardrails_iam_admin_promotion_policy_sns_target" {
  rule      = aws_cloudwatch_event_rule.guardrails_iam_admin_policy_monitoring_promotion.name
  target_id = "GuardrailsIAMAdminPromotionPolicySNSTarget"
  arn       = aws_sns_topic.guardrail_alerts.arn

  # Input transformer to format the alert message
  input_transformer {
    input_paths = {
      eventName       = "$.detail.eventName"
      eventTime       = "$.detail.eventTime"
      eventId         = "$.detail.eventId"
      sourceIPAddress = "$.detail.sourceIPAddress"
      userArn         = "$.detail.userIdentity.arn"
      awsRegion       = "$.detail.awsRegion"
      policyArn       = "$.detail.requestParameters.policyArn"
      targetUser      = "$.detail.requestParameters.userName"
      targetGroup     = "$.detail.requestParameters.groupName"
      targetRole      = "$.detail.requestParameters.roleName"
    }

    input_template = jsonencode({
      alert_type      = "IAM_ADMIN_POLICY_ATTACHMENT"
      severity        = "CRITICAL"
      event_name      = "<eventName>"
      event_time      = "<eventTime>"
      event_id        = "<eventId>"
      source_ip       = "<sourceIPAddress>"
      user_arn        = "<userArn>"
      region          = "<awsRegion>"
      policy_arn      = "<policyArn>"
      target_user     = "<targetUser>"
      target_group    = "<targetGroup>"
      target_role     = "<targetRole>"
      message         = "🚨 CRITICAL IAM ALERT: AdministratorAccess policy attached via '<eventName>' at <eventTime> by <userArn> from IP <sourceIPAddress>"
      action_required = "IMMEDIATE REVIEW REQUIRED: AdministratorAccess policy has been attached - verify this was authorized and follows principle of least privilege"
    })
  }
}

# EventBridge Rule for Breakglass User Console Sign-In Monitoring
resource "aws_cloudwatch_event_rule" "guardrails_breakglass_signin_monitoring" {
  name        = "guardrails-breakglass-signin-monitoring"
  description = "Monitor AWS Console sign-in events for breakglass IAM users"
  state       = "ENABLED"

  event_pattern = jsonencode({
    source      = ["aws.signin"]
    detail-type = ["AWS Console Sign In via CloudTrail"]
    detail = {
      eventName = ["ConsoleLogin"]
      userIdentity = {
        type     = ["IAMUser"]
        userName = ["ops1", "ops2"]
      }
    }
  })
}

# EventBridge Target - SNS Topic
resource "aws_cloudwatch_event_target" "guardrails_breakglass_signin_sns_target" {
  rule      = aws_cloudwatch_event_rule.guardrails_breakglass_signin_monitoring.name
  target_id = "GuardrailsBreakglassSignInSNSTarget"
  arn       = aws_sns_topic.guardrail_alerts.arn

  # Input transformer to format the alert message
  input_transformer {
    input_paths = {
      eventName        = "$.detail.eventName"
      eventTime        = "$.detail.eventTime"
      eventId          = "$.detail.eventId"
      sourceIPAddress  = "$.detail.sourceIPAddress"
      userArn          = "$.detail.userIdentity.arn"
      userName         = "$.detail.userIdentity.userName"
      userType         = "$.detail.userIdentity.type"
      awsRegion        = "$.detail.awsRegion"
      responseElements = "$.detail.responseElements"
      errorCode        = "$.detail.errorCode"
      errorMessage     = "$.detail.errorMessage"
    }

    input_template = jsonencode({
      alert_type      = "BREAKGLASS_SIGNIN_SECURITY_EVENT"
      severity        = "CRITICAL"
      event_name      = "<eventName>"
      event_time      = "<eventTime>"
      event_id        = "<eventId>"
      source_ip       = "<sourceIPAddress>"
      user_arn        = "<userArn>"
      user_name       = "<userName>"
      user_type       = "<userType>"
      region          = "<awsRegion>"
      login_status    = "<responseElements>"
      error_code      = "<errorCode>"
      error_message   = "<errorMessage>"
      message         = "🚨 BREAKGLASS ALERT: Emergency user '<userName>' accessed console at <eventTime> from IP <sourceIPAddress>"
      action_required = "IMMEDIATE REVIEW REQUIRED: Breakglass account used - verify emergency access was authorized and document the incident"
    })
  }
}

# EventBridge Rule for Root User Console Sign-In Monitoring
resource "aws_cloudwatch_event_rule" "guardrails_root_signin_monitoring" {
  name        = "guardrails-root-signin-monitoring"
  description = "Monitor AWS Console sign-in events for root user"
  state       = "ENABLED"

  event_pattern = jsonencode({
    detail-type = ["AWS Console Sign In via CloudTrail"]
    detail = {
      userIdentity = {
        type = ["Root"]
      }
      eventName = ["ConsoleLogin"]
    }
  })
}

# EventBridge Target - SNS Topic
resource "aws_cloudwatch_event_target" "guardrails_root_signin_sns_target" {
  rule      = aws_cloudwatch_event_rule.guardrails_root_signin_monitoring.name
  target_id = "GuardrailsRootSignInSNSTarget"
  arn       = aws_sns_topic.guardrail_alerts.arn

  # Input transformer to format the alert message
  input_transformer {
    input_paths = {
      eventName        = "$.detail.eventName"
      eventTime        = "$.detail.eventTime"
      eventId          = "$.detail.eventId"
      sourceIPAddress  = "$.detail.sourceIPAddress"
      userArn          = "$.detail.userIdentity.arn"
      userType         = "$.detail.userIdentity.type"
      awsRegion        = "$.detail.awsRegion"
      responseElements = "$.detail.responseElements"
      errorCode        = "$.detail.errorCode"
      errorMessage     = "$.detail.errorMessage"
      accountId        = "$.detail.userIdentity.accountId"
    }

    input_template = jsonencode({
      alert_type      = "ROOT_SIGNIN_SECURITY_EVENT"
      severity        = "CRITICAL"
      event_name      = "<eventName>"
      event_time      = "<eventTime>"
      event_id        = "<eventId>"
      source_ip       = "<sourceIPAddress>"
      user_arn        = "<userArn>"
      user_type       = "<userType>"
      account_id      = "<accountId>"
      region          = "<awsRegion>"
      login_status    = "<responseElements>"
      error_code      = "<errorCode>"
      error_message   = "<errorMessage>"
      message         = "🚨 CRITICAL ROOT ACCESS ALERT: Root user accessed console at <eventTime> from IP <sourceIPAddress>"
      action_required = "IMMEDIATE REVIEW REQUIRED: Root account used - verify this was authorized emergency access and document the incident. Root access should be extremely rare."
    })
  }
}