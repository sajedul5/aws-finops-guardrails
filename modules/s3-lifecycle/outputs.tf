output "bucket_ids" {
  description = "Buckets that received the lifecycle configuration."
  value       = [for c in aws_s3_bucket_lifecycle_configuration.this : c.bucket]
}

output "transitions" {
  description = "Effective storage-class transitions applied."
  value       = local.transitions
}
