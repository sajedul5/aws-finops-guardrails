# Getting started

Pick the level you need. Each one builds on the one before.

| Level | You need | Time | What you get |
|---|---|---|---|
| [1. Explore on your laptop](#1-explore-on-your-laptop-no-aws-account) | Nothing from AWS | 5 min | See it work against a fake AWS account |
| [2. Deploy from your laptop](#2-deploy-from-your-laptop) | An AWS account | 15 min | Real budget alerts and the scheduler in your account |
| [3. Deploy from GitHub Actions](#3-deploy-from-github-actions-oidc) | AWS account + GitHub repo | 30 min | Every change reviewed and approved, no AWS keys |

---

## 1. Explore on your laptop (no AWS account)

**Install:** [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.10, Python ≥ 3.11, `make`, `git`.

```bash
git clone https://github.com/sajedul5/aws-finops-guardrails.git
cd aws-finops-guardrails

make setup   # creates .venv with the test libraries (one time)
make demo    # the scheduler stops and starts servers in a FAKE AWS account
make test    # 38 Terraform tests and 12 Lambda tests, all offline
```

`make demo` shows the scheduler's safety rules in action:

```
🟢 dev-api       Schedule=office-hours   → stopped at 8 PM, started at 8 AM
🟢 prod-api      (no tag)                → never touched
🟢 dev-asg-node  in an Auto Scaling group → skipped safely
```

### Where to look
| Folder | What's inside |
|---|---|
| `modules/` | The six guardrails. Each has a README with inputs, outputs and an estimated benefit. |
| `examples/` | Ready-to-run setups: `single-account` (start here) and `complete` (everything). |
| `modules/offhours-scheduler/lambda/handler.py` | The Python code that stops and starts servers. |
| `tests/`, `modules/*/tests/` | How each rule is tested. |
| `demo/` | The fake-AWS demo. |

---

## 2. Deploy from your laptop

**Install:** everything from level 1, plus the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

**Use a test or personal account first, not production.** If it's a company account, ask your team before you apply.

### Step 1: Log in
```bash
aws login                      # opens the browser; or use a named profile:
export AWS_PROFILE=my-profile
aws sts get-caller-identity    # shows your account number = you're in
```

### Step 2: Check for an existing anomaly monitor
AWS allows only one all-services cost anomaly monitor per account, and creates one (`Default-Services-Monitor`) in many accounts.
```bash
aws ce get-anomaly-monitors --query "AnomalyMonitors[].MonitorName"
```
If this is not `[]`, set `enable_cost_anomaly = false` in step 3. Your existing monitor keeps working.

### Step 3: Your settings
```bash
cd examples/single-account
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars`:
```hcl
owner                     = "your-name"
monthly_budget_usd        = 1000
budget_alert_percentages  = [50, 80, 100]            # emails at $500, $800, $1,000
alert_emails              = ["you@example.com"]
alert_emails_no_aws_login = ["finance@example.com"]  # optional: people without AWS access
timezone                  = "Asia/Dhaka"
enable_cost_anomaly       = true                     # false if step 2 found a monitor
```

### Step 4: Preview, then create
```bash
terraform init
terraform plan     # shows what will be created; changes nothing
terraform apply    # type "yes"
```

### Step 5: Check it works
1. **Email:** click the AWS "Verify email" message while signed in to the account. People in `alert_emails_no_aws_login` click "Confirm subscription" instead, with no login needed.
2. **AWS Console:** open **Budgets** to see `finops-monthly-total`, and **Lambda** to see `finops-offhours-scheduler`.
3. **Scheduler test** (dry run, changes nothing):
   ```bash
   aws lambda invoke --function-name finops-offhours-scheduler \
     --cli-binary-format raw-in-base64-out --payload '{"action":"stop"}' out.json && cat out.json
   ```
4. **Tag a dev server** so it sleeps at night:
   ```bash
   aws ec2 create-tags --resources i-0123456789abcdef0 --tags Key=Schedule,Value=office-hours
   ```
5. After a week of correct dry-run logs, set `scheduler_dry_run = false` and apply again.

**Cost:** typically under $1/month.

**Remove everything:** `terraform destroy`

---

## 3. Deploy from GitHub Actions (OIDC)

GitHub logs in to AWS with a 1-hour token, so no AWS keys are stored anywhere. Pull requests show a plan, and merges apply it after your approval.

```
PR    → plan (read-only role)  → plan posted as a PR comment
Merge → you click Approve      → apply (apply role)
```

### Step 1: A bucket for the Terraform state
```bash
aws s3 mb s3://YOUR-NAME-tfstate-ACCOUNT_ID
aws s3api put-bucket-versioning --bucket YOUR-NAME-tfstate-ACCOUNT_ID \
  --versioning-configuration Status=Enabled
```

### Step 2: Your own repo
Create a **private** repo (for example `you/finops-live`) with this `main.tf`:

```hcl
terraform {
  required_version = ">= 1.10"
  backend "s3" {
    bucket       = "YOUR-NAME-tfstate-ACCOUNT_ID"
    key          = "finops/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "budgets" {
  source        = "github.com/sajedul5/aws-finops-guardrails//modules/budgets?ref=v0.1.1"
  monthly_limit = 1000
  alert_emails  = ["you@example.com"]
}

module "github_oidc" {
  source            = "github.com/sajedul5/aws-finops-guardrails//modules/github-oidc?ref=v0.1.1"
  github_repository = "you/finops-live"   # only this repo can log in
  state_bucket_name = "YOUR-NAME-tfstate-ACCOUNT_ID"
  apply_policy_arns = []                  # add a policy with only what your Terraform needs

  # If the account already has a GitHub OIDC provider
  # (check: aws iam list-open-id-connect-providers):
  # create_oidc_provider = false
  # oidc_provider_arn    = "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
}

output "plan_role_arn" {
  value = module.github_oidc.plan_role_arn
}

output "apply_role_arn" {
  value = module.github_oidc.apply_role_arn
}
```
Add the other modules the same way. Each module's README has an example.

### Step 3: First apply from your laptop
GitHub can't log in until the roles exist, so the first apply is local:
```bash
terraform init
terraform apply
```
Copy the two outputs.

### Step 4: GitHub settings (in your repo)
- **Settings → Secrets and variables → Actions → Variables:**
  - `AWS_PLAN_ROLE_ARN` = the `plan_role_arn` output
  - `AWS_APPLY_ROLE_ARN` = the `apply_role_arn` output
  - `AWS_REGION` = `us-east-1`
- **Settings → Environments → New environment:** `production`, then add yourself under **Required reviewers**.

### Step 5: Add the workflow
Copy [`examples/complete/deploy-workflow.yml`](../examples/complete/deploy-workflow.yml) to `.github/workflows/deploy.yml` in your repo and push.

From now on: change `main.tf` → open a PR → read the plan comment → merge → approve → done.

---

## Common problems

| Error | Fix |
|---|---|
| `Unable to locate credentials` | Run `aws login`, or `export AWS_PROFILE=...` |
| Anomaly monitor `Limit exceeded` on apply | Set `enable_cost_anomaly = false` |
| `EntityAlreadyExists` for the GitHub OIDC provider | Set `create_oidc_provider = false` and `oidc_provider_arn` |
| Config rule fails: no configuration recorder | `complete` example: set `enable_config_rule = false`, or turn on AWS Config first |
| "Verify email" needs an AWS login the person doesn't have | Move them to `alert_emails_no_aws_login` |
| No budget emails | Budgets data refreshes every 8–12 hours; alerts aren't instant |
| `make test` fails with `No module named pytest` | Run `make setup` first |
