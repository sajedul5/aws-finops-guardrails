variable "region" {
  description = "AWS region for regional resources (scheduler, Config rule, SNS)."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for every resource name."
  type        = string
  default     = "finops"
}

variable "owner" {
  description = "Owning team, applied as the Owner tag."
  type        = string
}

variable "cost_center" {
  description = "Cost center, applied as the CostCenter tag."
  type        = string
}

# --- Budgets and anomalies ---------------------------------------------------------

variable "monthly_budget_usd" {
  description = "Total monthly AWS budget in USD."
  type        = number
}

variable "service_budgets_usd" {
  description = "Per-service monthly budgets in USD, keyed by Cost Explorer service name."
  type        = map(number)
  default     = {}
}

variable "alert_emails" {
  description = "Who receives budget alert emails."
  type        = list(string)
}

variable "anomaly_threshold_usd" {
  description = "Immediate (SNS) anomaly alerts fire at or above this impact."
  type        = number
  default     = 100
}

# --- Tagging -------------------------------------------------------------------------

variable "required_tags" {
  description = "Cost-allocation tags every resource must carry, with allowed values ([] = any)."
  type        = map(list(string))
  default = {
    Owner       = []
    Environment = ["prod", "staging", "dev", "test"]
    CostCenter  = []
  }
}

variable "enable_config_rule" {
  description = "Create the AWS Config required-tags rule. Needs an AWS Config recorder in this account/region."
  type        = bool
  default     = true
}

variable "tag_policy_target_ids" {
  description = "Organization root/OU IDs for the tag policy. Empty = no tag policy (run from the management account to use it)."
  type        = list(string)
  default     = []
}

# --- Off-hours scheduler ---------------------------------------------------------

variable "timezone" {
  description = "IANA timezone for the off-hours schedule."
  type        = string
  default     = "UTC"
}

variable "scheduler_dry_run" {
  description = "Log only for the first week; set false to start saving."
  type        = bool
  default     = true
}

# --- S3 ------------------------------------------------------------------------------

variable "log_bucket_ids" {
  description = "Log/backup buckets: tier to IA then Glacier IR, and delete after log_retention_days."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Delete objects in log_bucket_ids after this many days. Null = keep forever."
  type        = number
  default     = 365
}

variable "data_bucket_ids" {
  description = "Data buckets with unpredictable access: Intelligent-Tiering, never deleted."
  type        = list(string)
  default     = []
}

# --- CI/CD ---------------------------------------------------------------------------

variable "github_repository" {
  description = "Repo allowed to plan/deploy via OIDC, as owner/name. Null = skip GitHub OIDC."
  type        = string
  default     = null
}

variable "github_create_oidc_provider" {
  description = "Create the GitHub OIDC provider (set false if the account already has one)."
  type        = bool
  default     = true
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN, when github_create_oidc_provider = false."
  type        = string
  default     = null
}

variable "state_bucket_name" {
  description = "Terraform state bucket the CI roles may use."
  type        = string
  default     = null
}

variable "deployer_policy_arns" {
  description = "Least-privilege policies for the CI apply role."
  type        = list(string)
  default     = []
}
