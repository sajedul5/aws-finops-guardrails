variable "name_prefix" {
  description = "Prefix for every budget and SNS topic name."
  type        = string
  default     = "finops"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,40}$", var.name_prefix))
    error_message = "name_prefix must be 1-40 characters: letters, numbers and hyphens."
  }
}

variable "monthly_limit" {
  description = "Total monthly account budget in USD."
  type        = number

  validation {
    condition     = var.monthly_limit > 0
    error_message = "monthly_limit must be greater than 0."
  }
}

variable "alert_thresholds" {
  description = "Percentages of the budget that trigger an ACTUAL-spend alert."
  type        = list(number)
  default     = [50, 80, 100]

  validation {
    condition     = alltrue([for t in var.alert_thresholds : t > 0 && t <= 1000])
    error_message = "Each threshold must be between 0 and 1000 percent."
  }
}

variable "forecast_threshold" {
  description = "Percentage of the budget that triggers a FORECASTED-spend alert. Set to null to disable."
  type        = number
  default     = 100
}

variable "service_budgets" {
  description = "Optional per-service monthly budgets in USD, keyed by the Cost Explorer service name (for example \"Amazon Elastic Compute Cloud - Compute\")."
  type        = map(number)
  default     = {}
}

variable "alert_emails" {
  description = "Email addresses that receive budget alerts directly from AWS Budgets."
  type        = list(string)
  default     = []
}

variable "create_sns_topic" {
  description = "Create an SNS topic for alerts (useful for Slack/Teams/chatbot integrations)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}
