# cost-anomaly

Catches the "someone left a GPU cluster running" moment. AWS Cost Anomaly Detection uses machine learning to learn your normal spend per service, and this module alerts you when a spike costs more than your threshold.

## What it creates
- A Cost Anomaly Detection monitor. By default it watches **every AWS service**.
- An alert subscription with a dollar-impact threshold
- For `IMMEDIATE` alerts, an encrypted SNS topic that only Cost Anomaly Detection in this account can publish to

## Usage
```hcl
# Immediate alerts through SNS (connect it to Slack/Teams via AWS Chatbot)
module "cost_anomaly" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/cost-anomaly?ref=v0.1.0"

  threshold_usd = 100
}

# Or a daily email digest
module "cost_anomaly_email" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/cost-anomaly?ref=v0.1.0"

  frequency     = "DAILY"
  alert_emails  = ["finops@example.com"]
  threshold_usd = 50
}
```

## Estimated benefit
Spikes are found in about **24 hours instead of at month-end**. A runaway resource costing $200/day caught on day 1 instead of day 30 avoids roughly $5,800 (typical estimate, assuming it would otherwise run all month).

## Notes
- AWS only supports SNS for `IMMEDIATE` alerts, and email only for `DAILY`/`WEEKLY`. The module picks the right one, and fails at plan time if `DAILY`/`WEEKLY` has no email.
- Cost Anomaly Detection itself is free.

<!-- BEGIN_TF_DOCS -->
## Inputs
| Name | Description | Type | Default |
|---|---|---|---|
| threshold_usd | Minimum total impact (USD) that triggers an alert | number | `100` |
| frequency | `IMMEDIATE` (SNS), `DAILY` or `WEEKLY` (email) | string | `"IMMEDIATE"` |
| alert_emails | Email subscribers for `DAILY`/`WEEKLY` | list(string) | `[]` |
| monitor_type | `DIMENSIONAL` (all services) or `CUSTOM` | string | `"DIMENSIONAL"` |
| monitor_specification | JSON expression for a `CUSTOM` monitor | string | `null` |
| name_prefix | Prefix for resource names | string | `"finops"` |
| tags | Tags for taggable resources | map(string) | `{}` |

## Outputs
| Name | Description |
|---|---|
| monitor_arn | Anomaly monitor ARN |
| subscription_arn | Alert subscription ARN |
| sns_topic_arn | SNS topic ARN, or `null` for `DAILY`/`WEEKLY` |
<!-- END_TF_DOCS -->
