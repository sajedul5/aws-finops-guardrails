---
name: new-module
description: Scaffold a new guardrail module in modules/<name>/ following this repo's conventions (versions, validated variables, safe defaults, outputs, README, CHANGELOG). Use when adding any new Terraform module to aws-finops-guardrails.
---

# Add a new guardrail module

Argument: the module name in kebab-case, for example `ri-coverage-alerts`. If none was given, ask for it.

## 1. Agree on scope first
Before writing code, tell the user in 3–5 lines:
- the cost problem it solves
- the AWS resources it will create
- which behaviour is **opt-in** (anything that deletes, stops or blocks)
- the expected benefit, labelled as an estimate

Wait for their go-ahead (see CLAUDE.md: one step at a time).

## 2. Create the files
`modules/<name>/`:

- **versions.tf**: copy from `modules/budgets/versions.tf`. Add other providers only if they're needed.
- **variables.tf**:
  - `name_prefix` (string, default `"finops"`) and `tags` (map(string), default `{}`)
  - every variable has `description` + `type`
  - add `validation` blocks for enums, ranges and formats
  - destructive features default to off (`null` / `false`)
- **main.tf**:
  - no `provider` block
  - optional resources use `count = var.create_x ? 1 : 0`
  - SNS topics: `kms_master_key_id = "alias/aws/sns"` and a topic policy scoped by `aws:SourceAccount`
  - IAM: least privilege, built with `aws_iam_policy_document` and no `*` actions
- **outputs.tf**: every output has a `description`; return `null` for resources that weren't created.
- **README.md**: use the template below.

## 3. README template
~~~markdown
# <name>

<One sentence: what it stops and why it saves money.>

## What it creates
- ...

## Usage
```hcl
module "<snake_name>" {
  source = "github.com/<owner>/aws-finops-guardrails//modules/<name>?ref=v0.1.0"
  # minimal required inputs
}
```

## Estimated benefit
<number + stated assumption, marked "typical estimate">

## Inputs / Outputs
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
~~~

## 4. Register it
- Add a line under `## [Unreleased] / ### Added` in `CHANGELOG.md`.
- Add a row to the module table in `README.md`, if the table exists.
- Wire it into `examples/complete/main.tf`, if that example exists.

## 5. Verify
Run `/validate`. Report the result, then stop and wait for the user.
