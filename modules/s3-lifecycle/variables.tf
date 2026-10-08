variable "bucket_ids" {
  description = "Names of existing buckets to apply the lifecycle configuration to. Note: this REPLACES any existing lifecycle configuration on those buckets."
  type        = set(string)
}

variable "prefix" {
  description = "Only objects under this key prefix are tiered and expired. Empty string = whole bucket."
  type        = string
  default     = ""
}

variable "transition_to_ia_days" {
  description = "Days after creation to move objects to STANDARD_IA. Null disables. Minimum 30."
  type        = number
  default     = 30

  validation {
    condition     = var.transition_to_ia_days == null || try(var.transition_to_ia_days >= 30, false)
    error_message = "transition_to_ia_days must be null or at least 30 (S3 minimum)."
  }
}

variable "transition_to_glacier_ir_days" {
  description = "Days after creation to move objects to GLACIER_IR. Null disables."
  type        = number
  default     = 90
}

variable "transition_to_deep_archive_days" {
  description = "Days after creation to move objects to DEEP_ARCHIVE. Null disables (default: off)."
  type        = number
  default     = null
}

variable "expiration_days" {
  description = "Days after creation to DELETE current objects. Null disables (default: off, data is never deleted)."
  type        = number
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep old object versions before deleting them. Null disables."
  type        = number
  default     = 90
}

variable "noncurrent_versions_to_keep" {
  description = "Number of newest noncurrent versions to keep regardless of age."
  type        = number
  default     = 3
}

variable "abort_incomplete_multipart_days" {
  description = "Days after which incomplete multipart uploads (invisible, but billed) are cleaned up."
  type        = number
  default     = 7
}

variable "use_intelligent_tiering" {
  description = "Move objects to INTELLIGENT_TIERING on day 0 instead of IA/Glacier IR. Best for unpredictable access."
  type        = bool
  default     = false
}
