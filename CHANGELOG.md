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
- `terraform test` suites for all four modules, using a mock AWS provider (no credentials needed).
- Claude Code setup: CLAUDE.md, hooks, `/new-module` and `/validate` skills, Makefile.
- Community files: LICENSE (MIT), CONTRIBUTING, CODEOWNERS, issue and PR templates.
