output "lambda_function_name" {
  value = aws_lambda_function.remediation.function_name
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.remediation_logs.name
}