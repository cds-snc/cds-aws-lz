import {
  to = aws_cloudwatch_event_rule.billing_extract_tags
  id = "default/billing_extract_tags_daily"
}

import {
  to = aws_cloudwatch_event_target.billing_extract_tags
  id = "billing_extract_tags_daily/terraform-20240305180415483500000002"
}

import {
  to = aws_iam_role.billing_extract_tags
  id = "BillingExtractTags"
}

import {
  to = aws_iam_policy.billing_extract_tags
  id = "arn:aws:iam::659087519042:policy/BillingExtractTags"
}

import {
  to = aws_iam_role_policy_attachment.billing_extract_tags
  id = "BillingExtractTags/arn:aws:iam::659087519042:policy/BillingExtractTags"
}

import {
  to = aws_iam_role_policy_attachment.org_read_only
  id = "BillingExtractTags/arn:aws:iam::aws:policy/AWSOrganizationsReadOnlyAccess"
}

import {
  to = aws_iam_role_policy_attachment.lambda_insights
  id = "BillingExtractTags/arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

import {
  to = aws_lambda_function.billing_extract_tags
  id = "billing_extract_tags"
}

import {
  to = aws_lambda_permission.billing_extract_tags
  id = "billing_extract_tags/AllowBillingExtractTagsDaily"
}

import {
  to = aws_cloudwatch_log_group.billing_extract_tags
  id = "/aws/lambda/billing_extract_tags"
}
