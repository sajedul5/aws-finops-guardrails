# budgets

Stops month-end bill surprises. It emails you, or posts to SNS, when spend crosses 50%, 80% or 100% of a monthly budget, and when AWS **forecasts** you'll go over.

## What it creates
- One total monthly cost budget for the account
- Optional per-service budgets (EC2, RDS, and so on)
- An SNS topic encrypted with the AWS-managed key. Its policy lets only AWS Budgets in this account publish.

## Usage
```hcl
module "budgets" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/budgets?ref=v0.1.0"

  monthly_limit = 5000
  alert_emails  = ["finops@example.com"]

  service_budgets = {
    "Amazon Elastic Compute Cloud - Compute" = 2000
    "Amazon Relational Database Service"     = 1000
  }
}
```

## Estimated benefit
Visibility from day one. Overspend is caught **during** the month, not on the invoice. Forecast alerts usually warn 1–2 weeks before the limit is hit (typical estimate; it depends on how steady spend is).

## Notes
- AWS Budgets data refreshes about every 8–12 hours, so alerts aren't real-time. Pair this with `cost-anomaly` to catch sudden spikes.
- This module creates monitoring-only budgets (no budget actions). AWS charges only for action-enabled budgets beyond the first two; check current [AWS Budgets pricing](https://aws.amazon.com/aws-cost-management/aws-budgets/pricing/).

<!-- BEGIN_TF_DOCS -->
## Inputs
| Name | Description | Type | Default |
|---|---|---|---|
| monthly_limit | Total monthly account budget in USD | number | required |
| alert_emails | Email subscribers | list(string) | `[]` |
| alert_thresholds | Actual-spend alert percentages | list(number) | `[50, 80, 100]` |
| forecast_threshold | Forecast alert percentage; `null` disables it | number | `100` |
| service_budgets | Per-service budgets in USD, keyed by Cost Explorer service name | map(number) | `{}` |
| create_sns_topic | Create an SNS topic for Slack/Teams/chatbot integrations | bool | `true` |
| name_prefix | Prefix for resource names | string | `"finops"` |
| tags | Tags for taggable resources | map(string) | `{}` |

## Outputs
| Name | Description |
|---|---|
| sns_topic_arn | Alert topic ARN, or `null` |
| monthly_budget_name | Name of the total budget |
| service_budget_names | Map of service name to budget name |
<!-- END_TF_DOCS -->
