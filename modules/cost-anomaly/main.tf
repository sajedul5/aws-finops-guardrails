data "aws_caller_identity" "current" {}

locals {
  use_sns = var.frequency == "IMMEDIATE"
}

resource "aws_ce_anomaly_monitor" "this" {
  name                  = "${var.name_prefix}-anomaly-monitor"
  monitor_type          = var.monitor_type
  monitor_dimension     = var.monitor_type == "DIMENSIONAL" ? "SERVICE" : null
  monitor_specification = var.monitor_type == "CUSTOM" ? var.monitor_specification : null
  tags                  = var.tags
}

resource "aws_sns_topic" "anomaly" {
  count = local.use_sns ? 1 : 0

  name              = "${var.name_prefix}-cost-anomalies"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

data "aws_iam_policy_document" "sns" {
  count = local.use_sns ? 1 : 0

  statement {
    sid       = "AllowCostAnomalyPublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.anomaly[0].arn]

    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "anomaly" {
  count = local.use_sns ? 1 : 0

  arn    = aws_sns_topic.anomaly[0].arn
  policy = data.aws_iam_policy_document.sns[0].json
}

resource "aws_ce_anomaly_subscription" "this" {
  name             = "${var.name_prefix}-anomaly-alerts"
  frequency        = var.frequency
  monitor_arn_list = [aws_ce_anomaly_monitor.this.arn]
  tags             = var.tags

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = [tostring(var.threshold_usd)]
    }
  }

  dynamic "subscriber" {
    for_each = local.use_sns ? [aws_sns_topic.anomaly[0].arn] : []
    content {
      type    = "SNS"
      address = subscriber.value
    }
  }

  dynamic "subscriber" {
    for_each = local.use_sns ? [] : var.alert_emails
    content {
      type    = "EMAIL"
      address = subscriber.value
    }
  }

  depends_on = [aws_sns_topic_policy.anomaly]

  lifecycle {
    precondition {
      condition     = local.use_sns || length(var.alert_emails) > 0
      error_message = "DAILY or WEEKLY frequency needs at least one address in alert_emails."
    }
  }
}
