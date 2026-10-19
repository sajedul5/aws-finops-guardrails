mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:us-east-1:111122223333:finops-cost-anomalies" }
  }
  mock_resource "aws_ce_anomaly_monitor" {
    defaults = { arn = "arn:aws:ce::111122223333:anomalymonitor/00000000-0000-0000-0000-000000000000" }
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

run "immediate_emails_through_sns" {
  command = apply

  variables {
    sns_email_subscribers = ["finops@example.com", "cto@example.com"]
  }

  assert {
    condition     = toset([for s in aws_sns_topic_subscription.email : s.endpoint]) == toset(["finops@example.com", "cto@example.com"])
    error_message = "Each SNS email subscriber should get one email subscription."
  }
}

run "sns_email_subscribers_need_immediate" {
  command = plan

  variables {
    frequency             = "DAILY"
    alert_emails          = ["finops@example.com"]
    sns_email_subscribers = ["cto@example.com"]
  }

  expect_failures = [aws_ce_anomaly_subscription.this]
}

run "invalid_email_is_rejected" {
  command = plan

  variables {
    sns_email_subscribers = ["finops@example"]
  }

  expect_failures = [var.sns_email_subscribers]
}
