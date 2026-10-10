---
name: validate
description: Check the whole repo is healthy: fmt, validate, terraform test, pytest, tflint, checkov and the minimum-provider check, the same as CI. Use after any change to Terraform, Lambda or workflow code, and before every commit.
---

# Validate the repo

Run from the repo root and report a short pass/fail table. CI runs the same `make` targets, so green here means green in the PR.

1. `make validate`: fmt check, then `init -backend=false` + `validate` in every `modules/*` and `examples/*`.
   - If fmt fails, run `make fmt` once and re-run.
   - If validate fails, fix the root cause. Don't silence it with `lifecycle.ignore_changes` or by deleting validations.
2. `make test`: `terraform test` for modules and examples (mock provider), then pytest.
3. `make min-provider`: each module at its lowest supported AWS provider. If it fails, either stop using the newer feature or raise the floor in **every** module's `versions.tf` and in `CLAUDE.md`.
4. `make lint` and `make security`, only if `tflint` / `checkov` are installed (check with `command -v`). If not, say "skipped (not installed), CI runs it". Don't install anything without asking.
   - checkov findings: fix them, or skip inline with a reason a client would accept (see CLAUDE.md).

## Report format
| Check | Result |
|---|---|
| fmt + validate (N dirs) | ✅ / ❌ which dir |
| terraform test | ✅ N passed / ❌ |
| pytest | ✅ N passed / ❌ |
| min-provider | ✅ / ❌ which module |
| tflint | ✅ / ❌ / skipped |
| checkov | ✅ / ❌ / skipped |

Never run `terraform plan`, `apply` or `destroy` as part of this skill.
