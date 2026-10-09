# Every guardrail in one stack: the setup for a company running AWS Organizations.
# Order follows a typical 4-week rollout: see, then attribute, then save, then automate.

locals {
  tags = { Component = "finops-guardrails" }
}

# Week 1-2: see the money --------------------------------------------------------

module "budgets" {
  source = "../../modules/budgets"

  name_prefix     = var.name_prefix
  monthly_limit   = var.monthly_budget_usd
  service_budgets = var.service_budgets_usd
  alert_emails    = var.alert_emails
  tags            = local.tags
}

# Spikes go to SNS immediately: connect AWS Chatbot to Slack/Teams, or subscribe an email.
# AWS allows only ONE all-services anomaly monitor per account, so there is exactly one here.
module "cost_anomaly" {
  source = "../../modules/cost-anomaly"

  name_prefix   = var.name_prefix
  frequency     = "IMMEDIATE"
  threshold_usd = var.anomaly_threshold_usd
  tags          = local.tags
}

# Week 3: attribute every dollar ------------------------------------------------

module "tag_enforcement" {
  source = "../../modules/tag-enforcement"

  name_prefix           = var.name_prefix
  required_tags         = var.required_tags
  create_config_rule    = var.enable_config_rule
  create_tag_policy     = length(var.tag_policy_target_ids) > 0
  tag_policy_target_ids = var.tag_policy_target_ids
  tags                  = local.tags
}

# Week 4: cut the waste ------------------------------------------------------------

module "offhours" {
  source = "../../modules/offhours-scheduler"

  name_prefix = var.name_prefix
  timezone    = var.timezone
  dry_run     = var.scheduler_dry_run
  tags        = local.tags
}

module "s3_logs" {
  source = "../../modules/s3-lifecycle"

  bucket_ids      = toset(var.log_bucket_ids)
  expiration_days = var.log_retention_days
}

module "s3_data" {
  source = "../../modules/s3-lifecycle"

  bucket_ids              = toset(var.data_bucket_ids)
  use_intelligent_tiering = true
}

# Ongoing: deploy changes through reviewed PRs, no stored AWS keys ---------------

module "github_oidc" {
  source = "../../modules/github-oidc"
  count  = var.github_repository == null ? 0 : 1

  name_prefix          = var.name_prefix
  github_repository    = var.github_repository
  create_oidc_provider = var.github_create_oidc_provider
  oidc_provider_arn    = var.github_oidc_provider_arn
  state_bucket_name    = var.state_bucket_name
  apply_policy_arns    = var.deployer_policy_arns
  tags                 = local.tags
}
