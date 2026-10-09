# Example: single account

The quickest way to stop AWS bill surprises in **one account**. It takes about 10 minutes and changes nothing that's already running.

| Guardrail | What you get |
|---|---|
| Budgets | Email at 50%, 80% and 100% of your monthly budget, and when AWS forecasts you'll go over |
| Cost anomaly detection | Daily email when spend jumps unexpectedly by more than the threshold |
| Off-hours scheduler | Stops tagged dev/test EC2 and RDS at 20:00 and starts them at 08:00, Mon–Fri. **Dry-run first.** |
| S3 lifecycle (optional) | Moves old objects to cheaper storage in the buckets you list |

## Run it
```bash
cp terraform.tfvars.example terraform.tfvars   # edit owner, budget, emails, timezone
terraform init
terraform plan                                  # review, then apply it yourself
```

## After the first deploy
1. **Confirm the emails.** AWS sends a confirmation email for anomaly alerts.
2. **Tag dev/test resources** that should sleep at night:
   ```bash
   aws ec2 create-tags --resources i-0123456789abcdef0 --tags Key=Schedule,Value=office-hours
   ```
3. **Watch the dry-run for a week.** Check the scheduler logs (the `scheduler_logs` output) to see what *would* be stopped. When you're happy, set `scheduler_dry_run = false`.

## Cost to run
Budgets, anomaly detection and IAM are free. The Lambda and the scheduler stay within the AWS free tier, and SNS costs about $0 at this volume. **Typically under $1/month.**

## Not included here
Tag enforcement needs AWS Config, and GitHub OIDC is only needed if you deploy from CI. See [`../complete`](../complete) for those.
