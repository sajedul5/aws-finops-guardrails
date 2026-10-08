output "sns_topic_arn" {
  description = "ARN of the budget alert SNS topic (null if not created)."
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : null
}

output "monthly_budget_name" {
  description = "Name of the total monthly budget."
  value       = aws_budgets_budget.monthly.name
}

output "service_budget_names" {
  description = "Map of service name to budget name."
  value       = { for k, b in aws_budgets_budget.service : k => b.name }
}
