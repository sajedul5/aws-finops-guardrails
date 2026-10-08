locals {
  transitions = var.use_intelligent_tiering ? [
    { days = 0, storage_class = "INTELLIGENT_TIERING" },
    ] : [
    for t in [
      { days = var.transition_to_ia_days, storage_class = "STANDARD_IA" },
      { days = var.transition_to_glacier_ir_days, storage_class = "GLACIER_IR" },
      { days = var.transition_to_deep_archive_days, storage_class = "DEEP_ARCHIVE" },
    ] : t if t.days != null
  ]

  transition_days = [for t in local.transitions : t.days]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = var.bucket_ids

  bucket = each.value

  rule {
    id     = "finops-tiering"
    status = "Enabled"

    filter {
      prefix = var.prefix
    }

    dynamic "transition" {
      for_each = local.transitions
      content {
        days          = transition.value.days
        storage_class = transition.value.storage_class
      }
    }

    dynamic "expiration" {
      for_each = var.expiration_days == null ? [] : [var.expiration_days]
      content {
        days = expiration.value
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_version_expiration_days == null ? [] : [var.noncurrent_version_expiration_days]
      content {
        noncurrent_days           = noncurrent_version_expiration.value
        newer_noncurrent_versions = var.noncurrent_versions_to_keep
      }
    }
  }

  rule {
    id     = "finops-abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_days
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for i in range(1, length(local.transition_days)) : local.transition_days[i] > local.transition_days[i - 1]
      ])
      error_message = "Transition days must increase: transition_to_ia_days < transition_to_glacier_ir_days < transition_to_deep_archive_days."
    }

    precondition {
      condition     = var.expiration_days == null || try(var.expiration_days > max(concat([0], local.transition_days)...), false)
      error_message = "expiration_days must be later than the last storage-class transition."
    }
  }
}
