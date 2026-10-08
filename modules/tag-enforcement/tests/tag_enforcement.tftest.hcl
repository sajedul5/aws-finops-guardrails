mock_provider "aws" {}

run "defaults_detect_only" {
  command = plan

  assert {
    condition     = length(aws_config_config_rule.required_tags) == 1
    error_message = "Config rule should be on by default."
  }

  assert {
    condition     = length(aws_organizations_policy.tags) == 0
    error_message = "Tag policy must be opt-in (safe default)."
  }

  assert {
    condition = jsondecode(aws_config_config_rule.required_tags[0].input_parameters) == {
      tag1Key   = "CostCenter"
      tag2Key   = "Environment"
      tag2Value = "prod,staging,dev,test"
      tag3Key   = "Owner"
    }
    error_message = "Config rule parameters are not rendered as tagNKey/tagNValue."
  }
}

run "tag_policy_opt_in" {
  command = plan

  variables {
    create_tag_policy          = true
    tag_policy_target_ids      = ["ou-abcd-12345678"]
    enforce_for_resource_types = ["ec2:instance"]
  }

  assert {
    condition     = jsondecode(aws_organizations_policy.tags[0].content).tags.environment.enforced_for["@@assign"] == ["ec2:instance"]
    error_message = "enforced_for should be rendered into the tag policy."
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.tags) == 1
    error_message = "Tag policy should be attached to each target."
  }
}

run "too_many_tags_is_rejected" {
  command = plan

  variables {
    required_tags = { a = [], b = [], c = [], d = [], e = [], f = [], g = [] }
  }

  expect_failures = [var.required_tags]
}
