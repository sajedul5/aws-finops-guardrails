mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

run "immediate_uses_sns" {
  command = plan

  assert {
    condition     = length(aws_sns_topic.anomaly) == 1
    error_message = "IMMEDIATE frequency must create an SNS topic."
  }

  assert {
    condition     = aws_ce_anomaly_monitor.this.monitor_dimension == "SERVICE"
    error_message = "Default monitor should watch every AWS service."
  }
}

run "daily_uses_email" {
  command = plan

  variables {
    frequency    = "DAILY"
    alert_emails = ["finops@example.com"]
  }

  assert {
    condition     = length(aws_sns_topic.anomaly) == 0
    error_message = "DAILY frequency should not create an SNS topic."
  }
}

run "daily_without_email_is_rejected" {
  command = plan

  variables {
    frequency = "WEEKLY"
  }

  expect_failures = [aws_ce_anomaly_subscription.this]
}

run "bad_frequency_is_rejected" {
  command = plan

  variables {
    frequency = "HOURLY"
  }

  expect_failures = [var.frequency]
}
