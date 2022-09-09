### Replace this with a tf module when I build it


data "archive_file" "spend_notifier" {
  type        = "zip"
  source_file = "${path.module}/lambdas/spend_notifier/spend_notifier.js"
  output_path = "/tmp/main.py.zip"
}


data "aws_iam_policy_document" "spend_notifier" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:ca-central-1:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity_current.account_id}:log-group:/aws/lambda/daily-spend-monitor:*"
    ]

  }

  statement {
    effect    = "Allow"
    actions   = ["ce:GetCostAndUsage"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "spend_notifier" {
  name   = "spend_notifier"
  policy = data.aws_iam_policy_document.spend_notifier.json
}

data "aws_iam_policy_document" "spend_notifier_role" {
  statement {
    effect  = "allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
      "sts:AssumeRole"]
    }
  }
}

data "aws_iam_policy" "org_read_only" {
  arn = "arn:aws:iam::aws:policy/AWSOrganizationsReadOnlyAccess"
}


resource "aws_iam_role" "spend_notifier" {
  name               = "spend_notifier_lambda"
  assume_role_policy = data.aws_iam_policy_document.spend_notifier_role.json
}

resource "aws_iam_role_policy_attachment" "spend_notifier" {
  role       = aws_iam_role.spend_notifier.name
  policy_arn = aws_iam_policy.spend_notifier.arn
}

resource "aws_iam_role_policy_attachment" "org_read_only" {
  role       = aws_iam_role.spend_notifier.name
  policy_arn = aws_iam_policy.org_read_only.arn
}

resource "aws_lambda_function" "spend_notifier" {
  function_name = "spend_notifier"
  role          = aws_iam_role.spend_notifier.arn
  runtime       = "nodejs16.x"
  handler       = "app.handler"
  memory_size   = 512

  filename         = data.archive_file.spend_notifier.output_path
  source_code_hash = filebase64sha256(data.archive_file.spend_notifier.output_path)

  reserved_concurrent_executions = var.reserved_concurrent_executions


  tracing_config {
    mode = "PassThrough"
  }

}

resource "aws_cloudwatch_event_rule" "weekly_budget_spend" {
  name                = "weekly_budget_spend"
  schedule_expression = "cron(0 12 ? * SUN *)"
}

resource "aws_cloudwatch_event_target" "weekly_budget_spend" {
  rule = aws_cloudwatch_event_rule.weekly_budget_spend.arn
  arn  = aws_lambda_function.spend_notifier.arn
  input = json(
    {
      "hook" : "${var.spend_notifier_hook}"
    }
  )
}

resource "aws_cloudwatch_event_rule" "daily_budget_spend" {
  name                = "daily_budget_spend"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_budget_spend" {
  rule = aws_cloudwatch_event_rule.daily_budget_spend.arn
  arn  = aws_lambda_function.spend_notifier.arn
  input = json(
    {
      "hook" : "${var.spend_notifier_hook}"
    }
  )
}



