data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "alerts" {
  count = var.create_sns_topic ? 1 : 0

  name              = "${var.name_prefix}-budget-alerts"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
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
  }
}

resource "aws_sns_topic_policy" "alerts" {
  count = var.create_sns_topic ? 1 : 0

  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.sns[0].json
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
