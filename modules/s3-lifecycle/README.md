# s3-lifecycle

Stops paying Standard prices for data nobody reads. It moves ageing objects to cheaper storage classes and cleans up two hidden costs: old object versions, and incomplete multipart uploads that you can't see but are still billed for.

## What it creates
For each bucket, an `aws_s3_bucket_lifecycle_configuration` with:
- **Tiering:** Standard-IA at 30 days, then Glacier Instant Retrieval at 90 days. Alternatively, Intelligent-Tiering from day 0.
- **Old versions:** deletes noncurrent versions after 90 days, keeping the newest 3.
- **Incomplete uploads:** aborted after 7 days.
- **Current objects are never deleted** unless you set `expiration_days`.

> ⚠️ A bucket has only one lifecycle configuration. This module **replaces** any existing rules on the buckets you pass in.

## Usage
```hcl
module "s3_lifecycle" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/s3-lifecycle?ref=v0.1.0"

  bucket_ids = ["my-app-logs", "my-backups"]
}

# Unpredictable access patterns: let S3 decide
module "s3_intelligent" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/s3-lifecycle?ref=v0.1.0"

  bucket_ids              = ["my-data-lake"]
  use_intelligent_tiering = true
}
```

## Estimated benefit
Standard-IA is about 45% cheaper per GB than Standard, and Glacier IR is about 80% cheaper (us-east-1 list prices: $0.023, $0.0125 and $0.004 per GB-month). On data that is mostly cold, expect **30–60% lower storage cost** (typical estimate; retrieval fees apply if cold data is read often).

## Notes
- Objects smaller than 128 KB aren't worth moving to IA or Glacier IR, because of minimum billable size.
- The module checks that transitions are in increasing order and that expiration comes after the last transition, so mistakes fail at `plan`, not at `apply`.

<!-- BEGIN_TF_DOCS -->
## Inputs
| Name | Description | Type | Default |
|---|---|---|---|
| bucket_ids | Existing bucket names | set(string) | required |
| prefix | Only tier and expire under this prefix (`""` = whole bucket) | string | `""` |
| transition_to_ia_days | Days to Standard-IA (≥ 30), or `null` | number | `30` |
| transition_to_glacier_ir_days | Days to Glacier IR, or `null` | number | `90` |
| transition_to_deep_archive_days | Days to Deep Archive, or `null` | number | `null` |
| use_intelligent_tiering | Use Intelligent-Tiering from day 0 instead | bool | `false` |
| expiration_days | Delete current objects after N days, or `null` (never) | number | `null` |
| noncurrent_version_expiration_days | Delete old versions after N days, or `null` | number | `90` |
| noncurrent_versions_to_keep | Newest old versions always kept | number | `3` |
| abort_incomplete_multipart_days | Abort incomplete uploads after N days | number | `7` |

## Outputs
| Name | Description |
|---|---|
| bucket_ids | Buckets configured |
| transitions | Effective storage-class transitions |
<!-- END_TF_DOCS -->
