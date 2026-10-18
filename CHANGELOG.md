# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.1] - 2026-10-18

### Added
- `make setup` and `make demo`: run the real scheduler Lambda against a fake AWS account (moto). No AWS account needed.
- `docs/GETTING_STARTED.md`: three levels (laptop demo, deploy from laptop, deploy from GitHub Actions with OIDC) and common errors.
- `single-account` example: `budget_alert_percentages` to choose the alert levels.

### Changed
- README quick start and CONTRIBUTING simplified; CONTRIBUTING no longer mentions tools the repo doesn't use.

### Fixed
- Examples: `enable_cost_anomaly` switch. Accounts that already have AWS's `Default-Services-Monitor` failed on apply, because AWS allows only one all-services monitor per account.

## [0.1.0] - 2026-10-18

First public release: six guardrail modules, two examples, CI with five required checks, and a client pitch page.

### Added
- Client pitch page (`docs/index.html`, served by GitHub Pages): problem, six guardrails, interactive savings calculator with stated assumptions, 4-week rollout, comparison table and contact. No external scripts; light and dark themes.
- README: CI and version badges, problem/solution table, Mermaid architecture diagram, module table with running costs, quick start, estimated savings with stated assumptions, "Built to be trusted" section and contact section.
- `budgets` module: monthly and per-service AWS Budgets with actual-spend and forecast alerts, optional encrypted SNS topic.
- `cost-anomaly` module: Cost Anomaly Detection monitor with an SNS (immediate) or email (daily/weekly) subscription.
- `tag-enforcement` module: AWS Config `required-tags` rule (on by default) and an opt-in Organizations tag policy.
- `s3-lifecycle` module: Standard-IA / Glacier IR tiering or Intelligent-Tiering, noncurrent-version expiry and incomplete-upload cleanup. Never deletes current objects by default.
- `offhours-scheduler` module: EventBridge Scheduler + Lambda that stops/starts EC2, RDS and Aurora tagged `Schedule=office-hours`. Tag-scoped IAM, dry-run mode, timezone support, pause switch. Skips Auto Scaling, Spot and read replicas.
- `github-oidc` module: keyless GitHub Actions access. A read-only plan role for PRs and main, and an apply role locked to one GitHub environment with no permissions by default. One repo only, audience pinned, optional Terraform state bucket access. 6 `terraform test` cases against the real trust-policy JSON.
- Examples: `single-account` (budgets, anomaly email, scheduler in dry-run, optional S3 tiering) and `complete` (all guardrails, 4-week rollout order, S3 backend with native locking). Each has a `terraform.tfvars.example` and a mock-provider plan test.
- CI (`.github/workflows/ci.yml`): five required checks on every PR: `terraform` (fmt, validate, tests), `min-provider`, `tflint`, `checkov` (Terraform + GitHub Actions) and `pytest`. Actions are pinned to commit SHAs, permissions are read-only.
- `scripts/check-min-provider.sh` and `make lint / security / min-provider / ci`.
- `examples/complete/deploy-workflow.yml`: OIDC deploy template. Plan comment on PRs; on merge, the reviewed plan is applied after `production` environment approval.
- Documented checkov exceptions on the scheduler Lambda (no VPC/NAT, no CMK, no X-Ray), each with its cost or risk reason.
- pytest suite for the scheduler Lambda (12 tests, moto) and 6 `terraform test` cases.
- `/step-done` skill: every finished step ends with commit, push and PR commands.
- `terraform test` suites for all four modules, using a mock AWS provider (no credentials needed).
- Claude Code setup: CLAUDE.md, hooks, `/new-module` and `/validate` skills, Makefile.
- Community files: LICENSE (MIT), CONTRIBUTING, CODEOWNERS, issue and PR templates.

### Fixed
- Guard hook no longer blocks commands that only *mention* deploy, merge or push commands inside heredoc text (for example docs and descriptions).
- Minimum AWS provider raised from 5.40 to 5.80. Budget `tags` and the `python3.13` Lambda runtime don't exist before 5.80; checked by validating every module at exactly 5.80.0.

[Unreleased]: https://github.com/sajedul5/aws-finops-guardrails/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/sajedul5/aws-finops-guardrails/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/sajedul5/aws-finops-guardrails/releases/tag/v0.1.0
