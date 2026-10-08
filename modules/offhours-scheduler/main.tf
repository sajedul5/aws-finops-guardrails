data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  function_name = "${var.name_prefix}-offhours-scheduler"
  schedules = merge(
    { stop = var.stop_schedule },
    var.start_schedule == null ? {} : { start = var.start_schedule },
  )
}

# --- Lambda package --------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# --- Lambda IAM: only resources carrying the schedule tag can be stopped/started ---

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  dynamic "statement" {
    for_each = var.include_ec2 ? [1] : []
    content {
      sid       = "DescribeEc2"
      actions   = ["ec2:DescribeInstances"]
      resources = ["*"] # Describe calls don't support resource-level permissions.
    }
  }

  dynamic "statement" {
    for_each = var.include_ec2 ? [1] : []
    content {
      sid       = "StopStartTaggedEc2"
      actions   = ["ec2:StopInstances", "ec2:StartInstances"]
      resources = ["arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"]

      condition {
        test     = "StringEquals"
        variable = "aws:ResourceTag/${var.schedule_tag_key}"
        values   = [var.schedule_tag_value]
      }
    }
  }

  dynamic "statement" {
    for_each = var.include_rds ? [1] : []
    content {
      sid       = "DescribeRds"
      actions   = ["rds:DescribeDBInstances", "rds:DescribeDBClusters"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.include_rds ? [1] : []
    content {
      sid       = "StopStartTaggedRdsInstances"
      actions   = ["rds:StopDBInstance", "rds:StartDBInstance"]
      resources = ["arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*"]

      condition {
        test     = "StringEquals"
        variable = "rds:db-tag/${var.schedule_tag_key}"
        values   = [var.schedule_tag_value]
      }
    }
  }

  dynamic "statement" {
    for_each = var.include_rds ? [1] : []
    content {
      sid       = "StopStartTaggedAuroraClusters"
      actions   = ["rds:StopDBCluster", "rds:StartDBCluster"]
      resources = ["arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*"]

      condition {
        test     = "StringEquals"
        variable = "rds:cluster-tag/${var.schedule_tag_key}"
        values   = [var.schedule_tag_value]
      }
    }
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "stop-start-tagged-resources"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  description      = "Stops/starts resources tagged ${var.schedule_tag_key}=${var.schedule_tag_value}."
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 300
  memory_size      = 128
  tags             = var.tags

  environment {
    variables = {
      TAG_KEY     = var.schedule_tag_key
      TAG_VALUE   = var.schedule_tag_value
      DRY_RUN     = tostring(var.dry_run)
      INCLUDE_EC2 = tostring(var.include_ec2)
      INCLUDE_RDS = tostring(var.include_rds)
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy.lambda]
}

# --- EventBridge Scheduler -------------------------------------------------------

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.function_name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "scheduler" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.this.arn]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name   = "invoke-offhours-lambda"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler.json
}

resource "aws_scheduler_schedule" "this" {
  for_each = local.schedules

  name                         = "${local.function_name}-${each.key}"
  description                  = "${title(each.key)} resources tagged ${var.schedule_tag_key}=${var.schedule_tag_value}."
  schedule_expression          = each.value
  schedule_expression_timezone = var.timezone
  state                        = var.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ action = each.key })

    retry_policy {
      maximum_retry_attempts       = 2
      maximum_event_age_in_seconds = 3600
    }
  }
}
