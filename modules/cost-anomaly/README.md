# cost-anomaly

Catches the "someone left a GPU cluster running" moment. AWS Cost Anomaly Detection uses machine learning to learn your normal spend per service, and this module alerts you when a spike costs more than your threshold.

## What it creates
- A Cost Anomaly Detection monitor. By default it watches **every AWS service**.
- An alert subscription with a dollar-impact threshold
- For `IMMEDIATE` alerts, an SNS topic, plus optional email subscriptions to it that only Cost Anomaly Detection in this account can publish to (not KMS-encrypted: AWS services can't publish to a topic using the AWS-managed SNS key, and alerts hold no secrets)

## Usage
```hcl
# Immediate alerts through SNS, to email (no AWS login needed to confirm)
# and/or Slack/Teams via AWS Chatbot
module "cost_anomaly" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/cost-anomaly?ref=v0.1.2"

  threshold_usd         = 100
  sns_email_subscribers = ["finops@example.com"]
}

# Or a daily email digest
module "cost_anomaly_email" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/cost-anomaly?ref=v0.1.2"

  frequency     = "DAILY"
  alert_emails  = ["finops@example.com"]
  threshold_usd = 50
}
```

## Estimated benefit
Spikes are found in about **24 hours instead of at month-end**. A runaway resource costing $200/day caught on day 1 instead of day 30 avoids roughly $5,800 (typical estimate, assuming it would otherwise run all month).

## Notes
- AWS only supports SNS for `IMMEDIATE` alerts, and email only for `DAILY`/`WEEKLY`. The module picks the right one, and fails at plan time if `DAILY`/`WEEKLY` has no email.
- **No AWS login needed with `sns_email_subscribers`:** each person clicks a "Confirm subscription" link from SNS. Direct `alert_emails` (DAILY/WEEKLY) may instead ask for a "Verify email" click while signed in to the account.
- **One per account:** AWS allows only one `DIMENSIONAL` (all-services) monitor per account. Use this module once per account, or use `CUSTOM` monitors for extra ones.
- Cost Anomaly Detection itself is free.

<!-- BEGIN_TF_DOCS -->
## Inputs
| Name | Description | Type | Default |
|---|---|---|---|
| threshold_usd | Minimum total impact (USD) that triggers an alert | number | `100` |
| frequency | `IMMEDIATE` (SNS), `DAILY` or `WEEKLY` (email) | string | `"IMMEDIATE"` |
| alert_emails | Email subscribers for `DAILY`/`WEEKLY` | list(string) | `[]` |
| sns_email_subscribers | Emails subscribed to the `IMMEDIATE` SNS topic; confirmation needs no AWS login | list(string) | `[]` |
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
