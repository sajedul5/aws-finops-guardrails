# offhours-scheduler

Stops paying for dev/test servers while everyone is asleep. Every weekday evening it stops the EC2 instances, RDS databases and Aurora clusters you've tagged, and it starts them again in the morning.

## How it works
```
EventBridge Scheduler ──20:00 Mon–Fri──▶ Lambda {"action":"stop"}  ──▶ EC2 / RDS / Aurora
                      ──08:00 Mon–Fri──▶ Lambda {"action":"start"} ──▶   tagged Schedule=office-hours
```
- **Opt-in per resource.** Only resources tagged `Schedule=office-hours` are touched. Untagged and production resources are never touched.
- **Least privilege.** IAM lets the Lambda stop and start **only** resources that carry the tag. The tag check is enforced by AWS IAM, not just by the code.
- **Skips what AWS can't safely stop:**
  - Auto Scaling group members, which the group would replace
  - Spot instances
  - RDS read replicas, and databases that have replicas
  - Aurora Serverless v1
- **Dry-run mode** logs what *would* happen without changing anything.
- **Every run** writes a JSON report to CloudWatch Logs. If any resource fails, the run is marked as failed, so the Lambda `Errors` metric shows it.

## Usage
```hcl
module "offhours" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/offhours-scheduler?ref=v0.1.0"

  timezone = "Asia/Dhaka"
  dry_run  = true # first week: watch the logs, then set to false
}
```
Then tag the resources that should sleep at night:
```bash
aws ec2 create-tags --resources i-0123456789abcdef0 --tags Key=Schedule,Value=office-hours
aws rds add-tags-to-resource --resource-name arn:aws:rds:us-east-1:111122223333:db:dev-db \
  --tags Key=Schedule,Value=office-hours
```
Test it straight away, without waiting for 20:00:
```bash
aws lambda invoke --function-name finops-offhours-scheduler \
  --cli-binary-format raw-in-base64-out --payload '{"action":"stop"}' out.json && cat out.json
```

## Estimated benefit
Running 08:00–20:00 Monday–Friday is 60 of 168 hours a week, so **about 64% fewer compute hours** for every tagged instance. A team with $3,000/month of dev/test EC2 and RDS saves about **$1,900/month** (typical estimate). EBS volumes and RDS storage are still billed while stopped.

Running cost: one Lambda invocation per schedule per day, well within the AWS free tier.

## Notes
- **AWS restarts stopped RDS and Aurora automatically after 7 days.** With the default weekday schedule this never happens. If you use `start_schedule = null` (stop only), a database that stays stopped longer will be started again by AWS.
- **Encrypted EBS volumes:** if a volume uses a customer-managed KMS key, the key policy must let the Lambda role use it, or the instance will fail to start.
- **Pausing:** set `enabled = false` to pause both schedules, for example during a release week or a late-night incident.
- **Times** follow `timezone` (IANA name) and adjust for daylight saving automatically.

<!-- BEGIN_TF_DOCS -->
## Inputs
| Name | Description | Type | Default |
|---|---|---|---|
| timezone | IANA timezone for both schedules | string | `"UTC"` |
| stop_schedule | Scheduler expression for stopping | string | `"cron(0 20 ? * MON-FRI *)"` |
| start_schedule | Scheduler expression for starting; `null` = stop only | string | `"cron(0 8 ? * MON-FRI *)"` |
| schedule_tag_key | Opt-in tag key | string | `"Schedule"` |
| schedule_tag_value | Opt-in tag value | string | `"office-hours"` |
| dry_run | Log only, change nothing | bool | `false` |
| enabled | `false` pauses both schedules | bool | `true` |
| include_ec2 | Manage EC2 instances | bool | `true` |
| include_rds | Manage RDS instances and Aurora clusters | bool | `true` |
| log_retention_days | CloudWatch Logs retention | number | `30` |
| name_prefix | Prefix for resource names | string | `"finops"` |
| tags | Tags for taggable resources | map(string) | `{}` |

## Outputs
| Name | Description |
|---|---|
| lambda_function_name | Lambda name, for `aws lambda invoke` |
| lambda_function_arn | Lambda ARN |
| log_group_name | Log group with a JSON report of every run |
| schedule_arns | Map of stop/start to schedule ARN |
| opt_in_tag | The tag a resource needs |
<!-- END_TF_DOCS -->
