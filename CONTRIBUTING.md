# Contributing

Thanks for helping make AWS bills less surprising.

## Ground rules
- Keep modules small and single-purpose. One guardrail per module.
- Every input needs a `description`, a `type`, and a `validation` block where it makes sense.
- Defaults must be **safe**: nothing should delete data or stop production by default.
- No long-lived AWS credentials anywhere. CI uses GitHub OIDC.

## Local setup
```bash
brew install terraform tflint terraform-docs pre-commit   # or your package manager
pip install -r tests/requirements.txt
pre-commit install
```

## Before opening a PR
```bash
terraform fmt -recursive
make validate      # init -backend=false + validate for every module and example
make test          # terraform test (mocked, needs Terraform >= 1.7) + pytest
```

## Commit messages
Use [Conventional Commits](https://www.conventionalcommits.org/): `feat(budgets): add per-account budgets`.

## Reporting a security issue
Please do not open a public issue. Email the maintainer instead.
