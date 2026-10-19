# Single AWS account: the four guardrails a small team gets the most value from.
# Nothing here deletes data or touches resources that aren't explicitly tagged.

module "budgets" {
  source = "../../modules/budgets"

  monthly_limit    = var.monthly_budget_usd
  alert_emails     = var.alert_emails
  alert_thresholds = var.budget_alert_percentages

  sns_email_subscribers = var.alert_emails_no_aws_login
}

module "cost_anomaly" {
  source = "../../modules/cost-anomaly"
  count  = var.enable_cost_anomaly ? 1 : 0

  # Daily email digest: the simplest setup, no SNS subscription to confirm.
  frequency     = "DAILY"
  alert_emails  = var.alert_emails
  threshold_usd = var.anomaly_threshold_usd
}

module "offhours" {
  source = "../../modules/offhours-scheduler"

  timezone = var.timezone
  dry_run  = var.scheduler_dry_run
}

module "s3_lifecycle" {
  source = "../../modules/s3-lifecycle"

  bucket_ids = toset(var.lifecycle_bucket_ids)
}
