# Contributing

Thanks for helping make AWS bills less surprising. Issues, ideas and pull requests are all welcome.

## Set up (5 minutes)
You need [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.10, Python ≥ 3.11, `make` and `git`. No AWS account is needed.

```bash
git clone https://github.com/sajedul5/aws-finops-guardrails.git
cd aws-finops-guardrails
make setup   # Python test libraries in .venv
make demo    # see the scheduler work against a fake AWS account
make test    # all tests, offline
```

Optional: `tflint` and `checkov` for `make lint` and `make security`. CI runs them anyway.

## Make a change
```bash
git switch -c feat/my-change
# edit, then:
make fmt
make ci        # the same checks CI runs (lint/security are skipped if not installed)
git commit -m "feat(budgets): add per-account budgets"
git push -u origin feat/my-change
gh pr create
```
`main` is protected: every change goes through a pull request, and five checks must pass (`terraform`, `min-provider`, `tflint`, `checkov`, `pytest`).

## Module rules
- **One guardrail per module**, small and single-purpose.
- Every variable has a `description`, a `type`, and a `validation` block where bad input is possible.
- **Safe defaults:** nothing deletes data, stops production or blocks resource creation unless the user opts in.
- No long-lived AWS keys anywhere. CI uses GitHub OIDC.
- Add or update tests (`modules/<name>/tests/` or `tests/`), the module README and `CHANGELOG.md`.
- Savings numbers are labelled as estimates, with the assumption stated.

## Commit messages
[Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `test:`, `ci:`, `chore:`.

## Security issues
Please don't open a public issue. Use [GitHub private vulnerability reporting](https://github.com/sajedul5/aws-finops-guardrails/security/advisories/new) instead.
