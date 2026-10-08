variable "name_prefix" {
  description = "Prefix for the monitor, subscription and SNS topic names."
  type        = string
  default     = "finops"
}

variable "monitor_type" {
  description = "DIMENSIONAL monitors every AWS service automatically. CUSTOM requires monitor_specification."
  type        = string
  default     = "DIMENSIONAL"

  validation {
    condition     = contains(["DIMENSIONAL", "CUSTOM"], var.monitor_type)
    error_message = "monitor_type must be DIMENSIONAL or CUSTOM."
  }
}

variable "monitor_specification" {
  description = "JSON cost-category/tag expression for a CUSTOM monitor. Ignored for DIMENSIONAL."
  type        = string
  default     = null
}

variable "threshold_usd" {
  description = "Alert only when the anomaly's total impact is at least this many USD."
  type        = number
  default     = 100

  validation {
    condition     = var.threshold_usd >= 0
    error_message = "threshold_usd cannot be negative."
  }
}

variable "frequency" {
  description = "IMMEDIATE (SNS only), DAILY or WEEKLY. Email subscribers require DAILY or WEEKLY."
  type        = string
  default     = "IMMEDIATE"

  validation {
    condition     = contains(["IMMEDIATE", "DAILY", "WEEKLY"], var.frequency)
    error_message = "frequency must be IMMEDIATE, DAILY or WEEKLY."
  }
}

variable "alert_emails" {
  description = "Email subscribers. Only used when frequency is DAILY or WEEKLY (an AWS restriction)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}
