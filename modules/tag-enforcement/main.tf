locals {
  tag_keys = keys(var.required_tags)

  # AWS Config required-tags takes tag1Key/tag1Value ... tag6Key/tag6Value; values are comma-separated.
  config_params = merge([
    for i, k in local.tag_keys : merge(
      { "tag${i + 1}Key" = k },
      length(var.required_tags[k]) > 0 ? { "tag${i + 1}Value" = join(",", var.required_tags[k]) } : {},
    )
  ]...)

  tag_policy = {
    tags = {
      for k, values in var.required_tags : lower(k) => merge(
        { tag_key = { "@@assign" = k } },
        length(values) > 0 ? { tag_value = { "@@assign" = values } } : {},
        length(var.enforce_for_resource_types) > 0 ? { enforced_for = { "@@assign" = var.enforce_for_resource_types } } : {},
      )
    }
  }
}

# --- Detect: AWS Config flags untagged resources -------------------------------

resource "aws_config_config_rule" "required_tags" {
  count = var.create_config_rule ? 1 : 0

  name        = "${var.name_prefix}-required-tags"
  description = "Flags resources missing cost-allocation tags: ${join(", ", local.tag_keys)}."

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode(local.config_params)

  dynamic "scope" {
    for_each = length(var.config_resource_types) > 0 ? [1] : []
    content {
      compliance_resource_types = var.config_resource_types
    }
  }

  tags = var.tags
}

# --- Standardise: Organizations tag policy -----------------------------------

resource "aws_organizations_policy" "tags" {
  count = var.create_tag_policy ? 1 : 0

  name        = "${var.name_prefix}-cost-allocation-tags"
  description = "Standard cost-allocation tag keys and values."
  type        = "TAG_POLICY"
  content     = jsonencode(local.tag_policy)
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "tags" {
  for_each = var.create_tag_policy ? toset(var.tag_policy_target_ids) : toset([])

  policy_id = aws_organizations_policy.tags[0].id
  target_id = each.value
}
