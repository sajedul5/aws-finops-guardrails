mock_provider "aws" {}

variables {
  bucket_ids = ["logs-bucket", "backups-bucket"]
}

run "safe_defaults" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this) == 2
    error_message = "One lifecycle configuration per bucket."
  }

  assert {
    condition     = jsonencode(output.transitions) == jsonencode([{ days = 30, storage_class = "STANDARD_IA" }, { days = 90, storage_class = "GLACIER_IR" }])
    error_message = "Default tiering should be IA at 30 days, Glacier IR at 90 days."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this["logs-bucket"].rule[0].expiration) == 0
    error_message = "Current objects must never be deleted by default."
  }
}

run "intelligent_tiering" {
  command = plan

  variables {
    use_intelligent_tiering = true
  }

  assert {
    condition     = jsonencode(output.transitions) == jsonencode([{ days = 0, storage_class = "INTELLIGENT_TIERING" }])
    error_message = "Intelligent-Tiering should replace the IA/Glacier ladder."
  }
}

run "out_of_order_transitions_rejected" {
  command = plan

  variables {
    transition_to_ia_days         = 60
    transition_to_glacier_ir_days = 45
  }

  expect_failures = [aws_s3_bucket_lifecycle_configuration.this]
}

run "expiration_before_tiering_rejected" {
  command = plan

  variables {
    expiration_days = 60
  }

  expect_failures = [aws_s3_bucket_lifecycle_configuration.this]
}

run "ia_under_30_days_rejected" {
  command = plan

  variables {
    transition_to_ia_days = 7
  }

  expect_failures = [var.transition_to_ia_days]
}
