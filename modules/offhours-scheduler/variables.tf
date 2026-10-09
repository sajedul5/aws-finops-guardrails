variable "name_prefix" {
  description = "Prefix for the Lambda function, IAM roles and schedules."
  type        = string
  default     = "finops"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,40}$", var.name_prefix))
    error_message = "name_prefix must be 1-40 characters: letters, numbers and hyphens."
  }
}

variable "schedule_tag_key" {
  description = "Tag key that opts a resource in to the off-hours schedule."
  type        = string
  default     = "Schedule"
}

variable "schedule_tag_value" {
  description = "Tag value that opts a resource in. Only resources with exactly this key=value are stopped and started."
  type        = string
  default     = "office-hours"

  validation {
    condition     = length(var.schedule_tag_value) > 0
    error_message = "schedule_tag_value can't be empty."
  }
}

variable "timezone" {
  description = "IANA timezone for both schedules, for example \"Asia/Dhaka\" or \"Europe/London\"."
  type        = string
  default     = "UTC"
}

variable "stop_schedule" {
  description = "EventBridge Scheduler expression for stopping resources. Default: 20:00 Monday-Friday."
  type        = string
  default     = "cron(0 20 ? * MON-FRI *)"

  validation {
    condition     = can(regex("^(cron|rate|at)\\(.+\\)$", var.stop_schedule))
    error_message = "stop_schedule must be a cron(...), rate(...) or at(...) expression."
  }
}

variable "start_schedule" {
  description = "EventBridge Scheduler expression for starting resources. Default: 08:00 Monday-Friday. Set to null to only stop (resources are started manually)."
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"

  validation {
    condition     = var.start_schedule == null || can(regex("^(cron|rate|at)\\(.+\\)$", var.start_schedule))
    error_message = "start_schedule must be null or a cron(...), rate(...) or at(...) expression."
  }
}

variable "enabled" {
  description = "Set to false to pause both schedules without destroying anything (for example during a release week)."
  type        = bool
  default     = true
}

variable "dry_run" {
  description = "Log what would be stopped/started without changing anything. Recommended for the first week."
  type        = bool
  default     = false
}

variable "include_ec2" {
  description = "Manage EC2 instances."
  type        = bool
  default     = true
}

variable "include_rds" {
  description = "Manage RDS instances and Aurora clusters."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the Lambda function."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a value CloudWatch Logs accepts (1, 3, 5, 7, 14, 30, 60, 90, ...)."
  }
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}
