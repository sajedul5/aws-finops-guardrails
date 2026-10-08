output "lambda_function_name" {
  description = "Name of the scheduler Lambda function (use it to test with `aws lambda invoke`)."
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "ARN of the scheduler Lambda function."
  value       = aws_lambda_function.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group with a JSON report of every run."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "schedule_arns" {
  description = "Map of action (stop/start) to EventBridge Scheduler schedule ARN."
  value       = { for k, s in aws_scheduler_schedule.this : k => s.arn }
}

output "opt_in_tag" {
  description = "The tag a resource needs to be included."
  value       = { (var.schedule_tag_key) = var.schedule_tag_value }
}
