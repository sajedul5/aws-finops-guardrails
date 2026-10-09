output "budget_alert_topic_arn" {
  description = "Subscribe Slack/Teams (AWS Chatbot) to this topic for budget alerts."
  value       = module.budgets.sns_topic_arn
}

output "scheduler_function_name" {
  description = "Test the scheduler now: aws lambda invoke --function-name <this> --payload '{\"action\":\"stop\"}' ..."
  value       = module.offhours.lambda_function_name
}

output "scheduler_logs" {
  description = "CloudWatch log group with a JSON report of every scheduler run."
  value       = module.offhours.log_group_name
}

output "opt_in_tag" {
  description = "Add this tag to dev/test EC2 and RDS resources that should sleep at night."
  value       = module.offhours.opt_in_tag
}
