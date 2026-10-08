output "config_rule_arn" {
  description = "ARN of the required-tags Config rule (null if not created)."
  value       = var.create_config_rule ? aws_config_config_rule.required_tags[0].arn : null
}

output "tag_policy_id" {
  description = "ID of the Organizations tag policy (null if not created)."
  value       = var.create_tag_policy ? aws_organizations_policy.tags[0].id : null
}

output "tag_policy_json" {
  description = "Rendered tag policy document, handy for review."
  value       = jsonencode(local.tag_policy)
}
