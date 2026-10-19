variable "region" {
  description = "AWS region for the scheduler and alert topics. Budgets and anomaly detection are global."
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Team or person responsible for these guardrails (added as the Owner tag)."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Expected monthly AWS spend in USD. Alerts fire at 50%, 80%, 100% and on a 100% forecast."
  type        = number
}

variable "alert_emails" {
  description = "Who receives budget and anomaly emails. Each person gets a \"Confirm subscription\" email from SNS; the link works without an AWS login."
  type        = list(string)
}

variable "budget_alert_percentages" {
  description = "Email when actual spend reaches these percentages of monthly_budget_usd. Example: budget 1600 with [62.5, 75, 100] alerts at $1,000, $1,200 and $1,600."
  type        = list(number)
  default     = [50, 80, 100]
}

variable "enable_cost_anomaly" {
  description = "Create the all-services cost anomaly monitor. Set false if the account already has one (AWS creates \"Default-Services-Monitor\" in many accounts, and allows only one)."
  type        = bool
  default     = true
}

variable "anomaly_threshold_usd" {
  description = "Only alert on cost anomalies with at least this much impact."
  type        = number
  default     = 50
}

variable "timezone" {
  description = "IANA timezone for the off-hours schedule, for example \"Asia/Dhaka\"."
  type        = string
  default     = "UTC"
}

variable "scheduler_dry_run" {
  description = "Start in dry-run: the scheduler only logs what it would stop. Set false after checking the logs."
  type        = bool
  default     = true
}

variable "lifecycle_bucket_ids" {
  description = "Existing S3 buckets to tier to cheaper storage. Empty = skip. This REPLACES existing lifecycle rules on them."
  type        = list(string)
  default     = []
}
