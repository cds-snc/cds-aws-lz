resource "aws_iam_role" "administration_role" {
  name = var.cloudformation_administration_role_name
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudformation.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Inline policy for the administration role
resource "aws_iam_role_policy" "assume_execution_role_policy" {
  name = "AssumeRole-AWSCloudFormationStackSetExecutionRole"
  role = aws_iam_role.administration_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:*:iam::*:role/${var.cloudformation_execution_role_name}"
      }
    ]
  })
}