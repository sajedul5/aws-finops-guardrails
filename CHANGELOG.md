# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `budgets` module: monthly and per-service AWS Budgets with actual-spend and forecast alerts, optional encrypted SNS topic.
- `cost-anomaly` module: Cost Anomaly Detection monitor with an SNS (immediate) or email (daily/weekly) subscription.
- `tag-enforcement` module: AWS Config `required-tags` rule (on by default) and an opt-in Organizations tag policy.
- `s3-lifecycle` module: Standard-IA / Glacier IR tiering or Intelligent-Tiering, noncurrent-version expiry and incomplete-upload cleanup. Never deletes current objects by default.
- `offhours-scheduler` module: EventBridge Scheduler + Lambda that stops/starts EC2, RDS and Aurora tagged `Schedule=office-hours`. Tag-scoped IAM, dry-run mode, timezone support, pause switch. Skips Auto Scaling, Spot and read replicas.
- pytest suite for the scheduler Lambda (12 tests, moto) and 6 `terraform test` cases.
- `/step-done` skill: every finished step ends with commit, push and PR commands.
- `terraform test` suites for all four modules, using a mock AWS provider (no credentials needed).
- Claude Code setup: CLAUDE.md, hooks, `/new-module` and `/validate` skills, Makefile.
- Community files: LICENSE (MIT), CONTRIBUTING, CODEOWNERS, issue and PR templates.

### Fixed
- Minimum AWS provider raised from 5.40 to 5.80. Budget `tags` and the `python3.13` Lambda runtime don't exist before 5.80; checked by validating every module at exactly 5.80.0.
