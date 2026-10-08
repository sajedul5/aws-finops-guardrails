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

run "default_weekday_schedule" {
  command = plan

  assert {
    condition     = aws_scheduler_schedule.this["stop"].schedule_expression == "cron(0 20 ? * MON-FRI *)"
    error_message = "Default stop should be 20:00 Monday-Friday."
  }

  assert {
    condition     = aws_scheduler_schedule.this["start"].schedule_expression == "cron(0 8 ? * MON-FRI *)"
    error_message = "Default start should be 08:00 Monday-Friday."
  }

  assert {
    condition     = jsondecode(aws_scheduler_schedule.this["stop"].target[0].input).action == "stop"
    error_message = "Stop schedule must send action=stop."
  }

  assert {
    condition     = aws_lambda_function.this.environment[0].variables.DRY_RUN == "false"
    error_message = "DRY_RUN should be passed to the Lambda as a string."
  }
}

run "timezone_and_pause" {
  command = plan

  variables {
    timezone = "Asia/Dhaka"
    enabled  = false
  }

  assert {
    condition     = alltrue([for s in aws_scheduler_schedule.this : s.schedule_expression_timezone == "Asia/Dhaka" && s.state == "DISABLED"])
    error_message = "Both schedules should use the timezone and be DISABLED when enabled = false."
  }
}

run "stop_only" {
  command = plan

  variables {
    start_schedule = null
  }

  assert {
    condition     = keys(aws_scheduler_schedule.this) == ["stop"]
    error_message = "Only a stop schedule should exist when start_schedule is null."
  }
}

run "custom_tag_reaches_lambda" {
  command = plan

  variables {
    schedule_tag_key   = "AutoStop"
    schedule_tag_value = "nights"
    dry_run            = true
  }

  assert {
    condition = (
      aws_lambda_function.this.environment[0].variables.TAG_KEY == "AutoStop" &&
      aws_lambda_function.this.environment[0].variables.TAG_VALUE == "nights" &&
      aws_lambda_function.this.environment[0].variables.DRY_RUN == "true"
    )
    error_message = "Tag and dry-run settings must reach the Lambda environment."
  }
}

run "bad_cron_is_rejected" {
  command = plan

  variables {
    stop_schedule = "0 20 * * 1-5"
  }

  expect_failures = [var.stop_schedule]
}

run "bad_retention_is_rejected" {
  command = plan

  variables {
    log_retention_days = 10
  }

  expect_failures = [var.log_retention_days]
}
