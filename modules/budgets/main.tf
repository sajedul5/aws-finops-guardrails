data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_sns_topic" "alerts" {
  #checkov:skip=CKV_AWS_26:AWS Budgets can't publish to a topic encrypted with the AWS-managed SNS key, and alerts hold only budget names and amounts.
  count = var.create_sns_topic ? 1 : 0

  name = "${var.name_prefix}-budget-alerts"
  tags = var.tags
}

data "aws_iam_policy_document" "sns" {
  count = var.create_sns_topic ? 1 : 0

  statement {
    sid       = "AllowBudgetsPublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.alerts[0].arn]

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:budgets::${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  count = var.create_sns_topic ? 1 : 0

  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.sns[0].json
}

# Each address gets a "Confirm subscription" email from SNS; the link works without an AWS login.
resource "aws_sns_topic_subscription" "email" {
  for_each = var.create_sns_topic ? toset(var.sns_email_subscribers) : toset([])

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

locals {
  sns_arns = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []

  # Every budget gets the same notification set: actual-spend thresholds + an optional forecast alert.
  notifications = concat(
    [for t in var.alert_thresholds : { type = "ACTUAL", threshold = t }],
    var.forecast_threshold == null ? [] : [{ type = "FORECASTED", threshold = var.forecast_threshold }],
  )
}

resource "aws_budgets_budget" "monthly" {
  name         = "${var.name_prefix}-monthly-total"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_limit)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  tags         = var.tags

  dynamic "notification" {
    for_each = local.notifications
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value.threshold
      threshold_type             = "PERCENTAGE"
      notification_type          = notification.value.type
      subscriber_email_addresses = var.alert_emails
      subscriber_sns_topic_arns  = local.sns_arns
    }
  }

  depends_on = [aws_sns_topic_policy.alerts]

  lifecycle {
    precondition {
      condition     = var.create_sns_topic || length(var.alert_emails) > 0
      error_message = "Budget alerts need a subscriber: set alert_emails or keep create_sns_topic = true."
    }
    precondition {
      condition     = var.create_sns_topic || length(var.sns_email_subscribers) == 0
      error_message = "sns_email_subscribers needs create_sns_topic = true."
    }
  }
}

resource "aws_budgets_budget" "service" {
  for_each = var.service_budgets

  name         = "${var.name_prefix}-${substr(replace(lower(each.key), "/[^a-z0-9]+/", "-"), 0, 60)}"
  budget_type  = "COST"
  limit_amount = tostring(each.value)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  tags         = var.tags

  cost_filter {
    name   = "Service"
    values = [each.key]
  }

  dynamic "notification" {
    for_each = local.notifications
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value.threshold
      threshold_type             = "PERCENTAGE"
      notification_type          = notification.value.type
      subscriber_email_addresses = var.alert_emails
      subscriber_sns_topic_arns  = local.sns_arns
    }
  }

  depends_on = [aws_sns_topic_policy.alerts]
}
