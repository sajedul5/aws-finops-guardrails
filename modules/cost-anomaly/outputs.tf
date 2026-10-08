output "monitor_arn" {
  description = "ARN of the Cost Anomaly Detection monitor."
  value       = aws_ce_anomaly_monitor.this.arn
}

output "subscription_arn" {
  description = "ARN of the anomaly alert subscription."
  value       = aws_ce_anomaly_subscription.this.arn
}

output "sns_topic_arn" {
  description = "ARN of the anomaly SNS topic (null when frequency is DAILY/WEEKLY)."
  value       = local.use_sns ? aws_sns_topic.anomaly[0].arn : null
}
