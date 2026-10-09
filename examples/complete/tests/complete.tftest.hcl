# Plans the whole stack against a mock AWS provider: catches wiring mistakes between modules.
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
  cost_center        = "CC-1001"
  monthly_budget_usd = 25000
  alert_emails       = ["finops@example.com"]
}

run "minimal_inputs" {
  command = plan

  assert {
    condition     = output.github_roles == null
    error_message = "GitHub OIDC should be skipped when github_repository is null."
  }

  assert {
    condition     = length(module.tag_enforcement.tag_policy_json) > 0
    error_message = "Tag policy should still render for review."
  }
}

run "everything_on" {
  command = plan

  variables {
    service_budgets_usd   = { "Amazon Relational Database Service" = 5000 }
    tag_policy_target_ids = ["r-abcd"]
    log_bucket_ids        = ["acme-alb-logs"]
    data_bucket_ids       = ["acme-data-lake"]
    github_repository     = "acme/infrastructure"
    state_bucket_name     = "acme-terraform-state"
  }

  assert {
    condition     = length(module.github_oidc) == 1
    error_message = "GitHub OIDC should be created when a repository is set."
  }
}

