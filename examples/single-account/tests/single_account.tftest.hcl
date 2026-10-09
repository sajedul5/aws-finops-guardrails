# Plans the whole example against a mock AWS provider: catches wiring mistakes between modules.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

variables {
  owner              = "platform-team"
  monthly_budget_usd = 2000
  alert_emails       = ["finops@example.com"]
}

run "plans_with_safe_defaults" {
  command = plan

  assert {
    condition     = module.offhours.opt_in_tag == { Schedule = "office-hours" }
    error_message = "Scheduler should use the documented opt-in tag."
  }
}

run "with_lifecycle_buckets" {
  command = plan

  variables {
    lifecycle_bucket_ids = ["my-app-logs"]
    scheduler_dry_run    = false
  }

  assert {
    condition     = module.s3_lifecycle.bucket_ids == ["my-app-logs"]
    error_message = "Lifecycle rules should be planned for the listed bucket."
  }
}
