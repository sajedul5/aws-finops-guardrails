output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (created or passed in)."
  value       = local.oidc_provider_arn
}

output "plan_role_arn" {
  description = "Read-only role for Terraform plan. Use it as role-to-assume in aws-actions/configure-aws-credentials."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Write role for Terraform deploys, usable only from the configured GitHub environment (null if not created)."
  value       = var.create_apply_role ? aws_iam_role.apply[0].arn : null
}

output "allowed_subjects" {
  description = "Exact GitHub OIDC subjects trusted by each role, for review."
  value = {
    plan  = local.plan_subjects
    apply = var.create_apply_role ? local.apply_subjects : []
  }
}
