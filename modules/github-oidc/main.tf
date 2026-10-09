data "aws_partition" "current" {}

locals {
  oidc_host         = "token.actions.githubusercontent.com"
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.oidc_provider_arn

  plan_subjects  = [for s in var.plan_allowed_subjects : "repo:${var.github_repository}:${s}"]
  apply_subjects = ["repo:${var.github_repository}:environment:${var.apply_environment}"]

  plan_policy_arns = [
    for p in var.plan_policy_arns : startswith(p, "arn:") ? p : "arn:${data.aws_partition.current.partition}:iam::aws:policy/${p}"
  ]

  state_bucket_arn = var.state_bucket_name == null ? null : "arn:${data.aws_partition.current.partition}:s3:::${var.state_bucket_name}"
}

# --- Identity provider (one per account) -------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
  # AWS validates GitHub tokens against its own trusted CA list; these values are
  # only kept because older AWS provider versions require the argument.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
  tags            = var.tags
}

# --- Trust policies: this repo only, audience sts.amazonaws.com ------------------

data "aws_iam_policy_document" "plan_trust" {
  lifecycle {
    precondition {
      condition     = var.create_oidc_provider || var.oidc_provider_arn != null
      error_message = "Set oidc_provider_arn when create_oidc_provider = false."
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_host}:sub"
      values   = local.plan_subjects
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  lifecycle {
    precondition {
      condition     = var.create_oidc_provider || var.oidc_provider_arn != null
      error_message = "Set oidc_provider_arn when create_oidc_provider = false."
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # StringEquals, not StringLike: only this exact environment, no wildcards.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = local.apply_subjects
    }
  }
}

# --- Plan role: read-only ----------------------------------------------------------

resource "aws_iam_role" "plan" {
  name                 = "${var.name_prefix}-github-plan"
  description          = "Read-only Terraform plan from GitHub Actions (${var.github_repository})."
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "plan" {
  for_each = toset(local.plan_policy_arns)

  role       = aws_iam_role.plan.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "plan_state" {
  count = var.state_bucket_name == null ? 0 : 1

  statement {
    sid       = "ReadState"
    actions   = ["s3:ListBucket", "s3:GetObject"]
    resources = [local.state_bucket_arn, "${local.state_bucket_arn}/*"]
  }

  statement {
    sid       = "StateLockFile"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/*.tflock"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  count = var.state_bucket_name == null ? 0 : 1

  name   = "terraform-state-read"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state[0].json
}

# --- Apply role: locked to one GitHub environment -------------------------------

resource "aws_iam_role" "apply" {
  count = var.create_apply_role ? 1 : 0

  name                 = "${var.name_prefix}-github-apply"
  description          = "Terraform deploys from GitHub Actions (${var.github_repository}, environment ${var.apply_environment})."
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "apply" {
  for_each = var.create_apply_role ? toset(var.apply_policy_arns) : toset([])

  role       = aws_iam_role.apply[0].name
  policy_arn = each.value
}

data "aws_iam_policy_document" "apply_state" {
  count = var.create_apply_role && var.state_bucket_name != null ? 1 : 0

  statement {
    sid       = "ReadWriteState"
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [local.state_bucket_arn, "${local.state_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "apply_state" {
  count = var.create_apply_role && var.state_bucket_name != null ? 1 : 0

  name   = "terraform-state-read-write"
  role   = aws_iam_role.apply[0].id
  policy = data.aws_iam_policy_document.apply_state[0].json
}
