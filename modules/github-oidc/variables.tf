variable "name_prefix" {
  description = "Prefix for the IAM role names."
  type        = string
  default     = "finops"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,40}$", var.name_prefix))
    error_message = "name_prefix must be 1-40 characters: letters, numbers and hyphens."
  }
}

variable "github_repository" {
  description = "The one GitHub repository allowed to assume the roles, as \"owner/name\". Wildcards are not allowed."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must be \"owner/name\" with no wildcards, for example \"sajedul5/aws-finops-guardrails\"."
  }
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC identity provider. An account can only have one, so set false and pass oidc_provider_arn if it already exists."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of an existing GitHub OIDC provider. Required when create_oidc_provider = false."
  type        = string
  default     = null
}

variable "plan_allowed_subjects" {
  description = "GitHub OIDC subject suffixes (after \"repo:owner/name:\") that may assume the read-only plan role."
  type        = list(string)
  default     = ["pull_request", "ref:refs/heads/main"]

  validation {
    condition     = length(var.plan_allowed_subjects) > 0 && alltrue([for s in var.plan_allowed_subjects : s != "*"])
    error_message = "plan_allowed_subjects can't be empty or a bare \"*\"."
  }
}

variable "plan_policy_arns" {
  description = "Managed policies for the plan role. Defaults to AWS ReadOnlyAccess. Use the short name of an AWS managed policy or a full ARN."
  type        = list(string)
  default     = ["ReadOnlyAccess"]
}

variable "create_apply_role" {
  description = "Create the apply role (write access). Set false for a plan-only setup."
  type        = bool
  default     = true
}

variable "apply_environment" {
  description = "GitHub environment the apply role is locked to. Add required reviewers to this environment in GitHub so every deploy needs approval."
  type        = string
  default     = "production"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.apply_environment))
    error_message = "apply_environment must be a plain GitHub environment name with no wildcards."
  }
}

variable "apply_policy_arns" {
  description = "Policies for the apply role (full ARNs). Nothing is attached by default, so grant only what your Terraform needs. Never AdministratorAccess in production."
  type        = list(string)
  default     = []
}

variable "state_bucket_name" {
  description = "S3 bucket holding Terraform state. When set, plan can read state and write the lock file, and apply can read and write state."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum role session length in seconds (1 to 12 hours)."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}
