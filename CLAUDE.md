# aws-finops-guardrails

Open-source Terraform modules that stop AWS bill surprises. This is a portfolio project: it has to impress prospective clients and be easy for the community to reuse. Polish and clear docs matter more than extra features.

## How we work
- **One step at a time.** The plan's steps are listed in `docs/ROADMAP.md`. Finish one step, show what changed and its benefit, then wait for the user's go-ahead.
- **Every finished step ends with the ship commands.** Claude doesn't commit or push itself. It runs `/step-done`, which prints the exact `git add` (only that step's files), `git commit`, `git push`, `gh pr create` and post-merge sync commands for the user to run. One commit per step, on a feature branch, using Conventional Commits.
- **Never push to `main`.** A GitHub ruleset (`protect-main`) blocks direct pushes, force-pushes and deletion for everyone, admins included, and a hook blocks it locally too. The flow is always:
  `git switch main && git pull` → `git switch -c <type>/<short-name>` → commit → `git push -u origin <branch>` → `gh pr create`.
  Only the repo owner (@sajedul5) merges. Claude never runs `gh pr merge`.
- Never run `terraform apply` or `destroy`; a hook blocks them. `plan` against a sandbox account is fine when the user asks.

## Layout
```
modules/<name>/      one guardrail per module: main.tf, variables.tf, outputs.tf, versions.tf, README.md
examples/<name>/     runnable compositions of modules (single-account, complete)
tests/               pytest + moto for Lambda code
scripts/             CI helpers (check-min-provider.sh)
.github/workflows/   ci.yml: the five required checks on every PR
.claude/             hooks (scripts in .claude/hooks/) and skills (/new-module, /validate, /step-done)
```

## Commands
```bash
make fmt           # terraform fmt -recursive
make validate      # fmt check + init -backend=false + validate for every module and example
make test          # terraform test (mock provider) + pytest
make lint          # tflint with the AWS ruleset
make security      # checkov on Terraform and GitHub Actions
make min-provider  # validate each module at its lowest supported AWS provider
make ci            # all of the above, exactly what CI runs
```
CI (`.github/workflows/ci.yml`) runs five jobs, and all are required before merging: `terraform`, `min-provider`, `tflint`, `checkov`, `pytest`. Actions are pinned to commit SHAs; Dependabot updates them.

## Security scan exceptions
A checkov finding is either fixed or skipped inline with a reason (`#checkov:skip=CKV_X:why`). Never skip without a reason that a client would accept. The current skips are on the scheduler Lambda (see `modules/offhours-scheduler/main.tf`).

## Module rules
- `versions.tf`: Terraform `>= 1.5.0`, AWS provider `>= 5.80` (the lowest version that supports budget tags and the python3.13 Lambda runtime). Modules never configure a `provider` block; examples do.
- Every variable has a `description` and a `type`, plus a `validation` block when bad input is possible.
- Every module takes `name_prefix` (default `"finops"`) and `tags` (default `{}`) where it creates taggable resources.
- **Safe defaults:** nothing deletes data, stops production, or blocks resource creation unless the user opts in (examples: `s3-lifecycle.expiration_days = null`, `tag-enforcement.create_tag_policy = false`).
- SNS topics use `kms_master_key_id = "alias/aws/sns"`, and topic policies are scoped with `aws:SourceAccount`.
- Optional resources use `count = var.create_x ? 1 : 0`. Outputs return `null` when the resource isn't created.
- When a module changes, update its README and `CHANGELOG.md` under `[Unreleased]`.

## Savings claims
There's no real client data. Any savings number in docs or the pitch page must be labelled as a typical estimate, with its assumption stated (for example: "off-hours: 12h × 5 days running out of 168h/week ≈ 64% fewer hours").

## Tooling notes
- Hooks need `jq` and `terraform` on PATH.
- `tflint` and `checkov` are optional locally; CI runs them. Override the binaries with `make lint TFLINT=/path/to/tflint` or `make security CHECKOV=/path/to/checkov`.
- The Bash tool runs **zsh**: unquoted `$var` isn't word-split. Use arrays or pass arguments explicitly in loops.
