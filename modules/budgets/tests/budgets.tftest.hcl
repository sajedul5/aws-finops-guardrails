mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
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
