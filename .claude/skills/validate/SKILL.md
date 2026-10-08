---
name: validate
description: Check the whole repo is healthy: terraform fmt, init/validate for every module and example, optional tflint/checkov, and pytest. Use after any change to Terraform or Lambda code, and before every commit.
---

# Validate the repo

Run from the repo root and report a short pass/fail table.

1. `make validate`: fmt check, then `init -backend=false` + `validate` in every `modules/*` and `examples/*`.
   - If fmt fails, run `make fmt` once and re-run.
   - If validate fails, fix the root cause in the module, then re-run. Don't silence it with `lifecycle.ignore_changes` or by deleting validations.
2. `make test`: pytest for Lambda code (it says "No tests yet" if there are none).
3. Optional, only if installed (check with `command -v`):
   - `tflint --recursive`
   - `checkov -d . --quiet --compact`

   If a tool isn't installed, say "skipped (not installed), CI runs it". Don't install anything without asking.

## Report format
| Check | Result |
|---|---|
| fmt | ✅ / ❌ |
| validate (N dirs) | ✅ / ❌ which dir |
| pytest | ✅ / ❌ / none |
| tflint | ✅ / ❌ / skipped |
| checkov | ✅ / ❌ / skipped |

Never run `terraform plan`, `apply` or `destroy` as part of this skill.
