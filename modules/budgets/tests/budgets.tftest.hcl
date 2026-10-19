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
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:us-east-1:111122223333:finops-budget-alerts" }
  }
}

variables {
  monthly_limit = 1000
  alert_emails  = ["finops@example.com"]
}

run "default_alerts" {
  # Mocked apply: fake ARNs are generated, nothing is sent to AWS.
  command = apply

  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 4
    error_message = "Expected 3 actual-spend alerts (50/80/100%) plus 1 forecast alert."
  }

  assert {
    condition     = aws_budgets_budget.monthly.limit_amount == "1000"
    error_message = "Monthly limit not passed through."
  }

  assert {
    condition     = length(aws_sns_topic.alerts) == 1
    error_message = "SNS topic should be created by default."
  }
}

run "forecast_disabled" {
  command = apply

  variables {
    forecast_threshold = null
  }

  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 3
    error_message = "Forecast alert should be removed when forecast_threshold is null."
  }
}

run "service_budget_name_is_sanitised" {
  command = plan

  variables {
    service_budgets = { "Amazon Elastic Compute Cloud - Compute" = 400 }
  }

  assert {
    condition     = aws_budgets_budget.service["Amazon Elastic Compute Cloud - Compute"].name == "finops-amazon-elastic-compute-cloud-compute"
    error_message = "Service budget name should be lower-case and hyphenated."
  }
}

run "no_subscriber_is_rejected" {
  command = plan

  variables {
    alert_emails     = []
    create_sns_topic = false
  }

  expect_failures = [aws_budgets_budget.monthly]
}

run "invalid_limit_is_rejected" {
  command = plan

  variables {
    monthly_limit = 0
  }

  expect_failures = [var.monthly_limit]
}

run "sns_email_subscribers_need_no_aws_login" {
  command = apply

  variables {
    sns_email_subscribers = ["finance@example.com", "hr@example.com"]
  }

  assert {
    condition     = toset([for s in aws_sns_topic_subscription.email : s.endpoint]) == toset(["finance@example.com", "hr@example.com"])
    error_message = "Each SNS email subscriber should get one email subscription."
  }

  assert {
    condition     = alltrue([for s in aws_sns_topic_subscription.email : s.protocol == "email"])
    error_message = "SNS subscriptions should use the email protocol."
  }
}

run "topic_is_not_kms_encrypted" {
  # AWS Budgets can't publish to a topic encrypted with the AWS-managed SNS key.
  command = plan

  assert {
    condition     = aws_sns_topic.alerts[0].kms_master_key_id == null || aws_sns_topic.alerts[0].kms_master_key_id == ""
    error_message = "The budget alert topic must not use alias/aws/sns, or Budgets can't deliver to it."
  }
}

run "sns_email_subscribers_need_the_topic" {
  command = plan

  variables {
    create_sns_topic      = false
    sns_email_subscribers = ["finance@example.com"]
  }

  expect_failures = [aws_budgets_budget.monthly]
}

run "invalid_email_is_rejected" {
  command = plan

  variables {
    alert_emails = ["shakil@the-data-island"]
  }

  expect_failures = [var.alert_emails]
}
