# Example: complete

Every guardrail in one stack, for a company using AWS Organizations. The modules follow the order of a typical 4-week FinOps rollout:

| Week | Goal | Modules |
|---|---|---|
| 1–2 | **See** the money | `budgets` (total + per service), `cost-anomaly` (immediate SNS alerts) |
| 3 | **Attribute** every dollar | `tag-enforcement` (Config rule + optional Organizations tag policy) |
| 4 | **Cut** the waste | `offhours-scheduler` (dry-run first), `s3-lifecycle` (logs: tier + expire; data: Intelligent-Tiering) |
| Ongoing | **Automate** safely | `github-oidc` (PR plans, approved deploys, no stored keys) |

## Run it
```bash
cp terraform.tfvars.example terraform.tfvars   # edit owner, budgets, emails, buckets
terraform init
terraform plan                                  # review, then apply it yourself
```

## Before you start
- **AWS Config recorder:** the required-tags rule needs one. If the account has none, set `enable_config_rule = false`.
- **Tag policy:** only from the Organizations **management** (or delegated admin) account. Set `tag_policy_target_ids` to your root or OU IDs.
- **Remote state:** uncomment the `backend "s3"` block in `versions.tf`. It uses native S3 locking (Terraform ≥ 1.10), so no DynamoDB table is needed.
- **GitHub OIDC:** an account can have only one GitHub OIDC provider. If one exists, set `github_create_oidc_provider = false` and `github_oidc_provider_arn`.

## After the first deploy
1. Connect the `alert_topics` outputs to Slack or Teams with AWS Chatbot, or subscribe an email address.
2. Activate `Owner`, `Environment` and `CostCenter` as **cost allocation tags** in the Billing console.
3. Tag dev/test resources with `Schedule=office-hours`, check a week of dry-run logs, then set `scheduler_dry_run = false`.
4. If you use CI: copy the `github_roles` outputs into GitHub repository variables `AWS_PLAN_ROLE_ARN` and `AWS_APPLY_ROLE_ARN`, and add required reviewers to the `production` environment.

## Cost to run
Budgets, anomaly detection, tag policies and IAM are free. The Lambda, scheduler and SNS cost about $0. The AWS Config rule costs about $1–30/month depending on how many resources change. **Typically under $30/month**, against savings that are usually hundreds to thousands of dollars (typical estimate).
