# Run `make help` to list targets.
DIRS := $(sort $(dir $(wildcard modules/*/versions.tf examples/*/main.tf)))

.PHONY: help fmt fmt-check validate test

help:
	@echo "fmt        Format all Terraform files"
	@echo "fmt-check  Fail if any Terraform file is not formatted"
	@echo "validate   fmt-check + init/validate every module and example"
	@echo "test       Run pytest for Lambda code"

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check -diff

validate: fmt-check
	@set -e; for d in $(DIRS); do \
		echo "==> $$d"; \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$d validate -no-color; \
	done

test:
	@if [ -d tests ] && ls tests/test_*.py >/dev/null 2>&1; then \
		python3 -m pytest -q tests; \
	else \
		echo "No tests yet"; \
	fi
