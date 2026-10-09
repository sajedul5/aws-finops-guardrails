# Uses the real AWS provider offline (fake credentials, no API calls) so the
# assertions check the exact trust-policy JSON that AWS would receive.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  github_repository    = "sajedul5/aws-finops-guardrails"
  create_oidc_provider = false
  oidc_provider_arn    = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
}

run "plan_role_trusts_only_this_repo" {
  command = plan

  assert {
    condition = jsondecode(aws_iam_role.plan.assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] == [
      "repo:sajedul5/aws-finops-guardrails:pull_request",
      "repo:sajedul5/aws-finops-guardrails:ref:refs/heads/main",
    ]
    error_message = "Plan role must trust only pull requests and main of this repo."
  }

  assert {
    condition     = jsondecode(aws_iam_role.plan.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"
    error_message = "Audience must be pinned to sts.amazonaws.com."
  }

  assert {
    condition     = keys(aws_iam_role_policy_attachment.plan) == ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    error_message = "Plan role should get ReadOnlyAccess by default."
  }
}

run "apply_role_locked_to_environment" {
  command = plan

  assert {
    condition     = jsondecode(aws_iam_role.apply[0].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:sajedul5/aws-finops-guardrails:environment:production"
    error_message = "Apply role must trust only the production environment, with an exact match."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.apply) == 0
    error_message = "Apply role must get no permissions unless the user grants them."
  }
}

run "state_bucket_permissions" {
  command = plan

  variables {
    state_bucket_name = "my-tf-state"
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.plan_state[0].policy).Statement[1].Resource == "arn:aws:s3:::my-tf-state/*.tflock"
    error_message = "Plan role may only write the state lock file."
  }

  assert {
    condition     = length(aws_iam_role_policy.apply_state) == 1
    error_message = "Apply role should get state read/write when a bucket is set."
  }
}

run "plan_only_setup" {
  command = plan

  variables {
    create_apply_role = false
  }

  assert {
    condition     = length(aws_iam_role.apply) == 0 && output.apply_role_arn == null
    error_message = "No apply role should exist when create_apply_role = false."
  }
}

run "wildcard_repo_is_rejected" {
  command = plan

  variables {
    github_repository = "sajedul5/*"
  }

  expect_failures = [var.github_repository]
}

run "missing_provider_arn_is_rejected" {
  command = plan

  variables {
    oidc_provider_arn = null
  }

  expect_failures = [data.aws_iam_policy_document.plan_trust, data.aws_iam_policy_document.apply_trust]
}
