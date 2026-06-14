# Zip the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/remediation.py"
  output_path = "${path.module}/../lambda/remediation.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "config:GetComplianceDetailsByResource",
          "config:DescribeConfigRules"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "remediation_logs" {
  name              = "/drift-detection/remediation"
  retention_in_days = 30

  tags = {
    Name      = "${var.project_name}-logs"
    ManagedBy = "Terraform"
  }
}

# Lambda Function
resource "aws_lambda_function" "remediation" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-remediation"
  role             = aws_iam_role.lambda_role.arn
  handler          = "remediation.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      EC2_INSTANCE_ID   = aws_instance.project_ec2.id
      SECURITY_GROUP_ID = aws_security_group.project_sg.id
      LOG_GROUP_NAME    = "/drift-detection/remediation"
    }
  }

  tags = {
    Name      = "${var.project_name}-lambda"
    ManagedBy = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.remediation_logs
  ]
}

# EventBridge rule - runs every 5 minutes
resource "aws_cloudwatch_event_rule" "drift_schedule" {
  name                = "${var.project_name}-drift-schedule"
  description         = "Trigger drift detection every 5 minutes"
  schedule_expression = "rate(5 minutes)"

  tags = {
    Name      = "${var.project_name}-schedule"
    ManagedBy = "Terraform"
  }
}

# EventBridge target - triggers Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.drift_schedule.name
  target_id = "RemediationLambda"
  arn       = aws_lambda_function.remediation.arn
}

# Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.drift_schedule.arn
}
