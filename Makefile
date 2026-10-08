# Run `make help` to list targets.
DIRS := $(sort $(dir $(wildcard modules/*/versions.tf examples/*/main.tf)))
PYTHON ?= python3
TF_TEST_DIRS := $(sort $(patsubst %/tests/,%/,$(dir $(wildcard modules/*/tests/*.tftest.hcl))))

.PHONY: help fmt fmt-check validate test tftest pytest

help:
	@echo "fmt        Format all Terraform files"
	@echo "fmt-check  Fail if any Terraform file is not formatted"
	@echo "validate   fmt-check + init/validate every module and example"
	@echo "test       tftest + pytest"
	@echo "tftest     terraform test (mock AWS provider, no credentials needed)"
	@echo "pytest     pytest for Lambda code"

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

test: tftest pytest

tftest:
	@set -e; for d in $(TF_TEST_DIRS); do \
		echo "==> $$d"; \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$d test -no-color; \
	done

pytest:
	@if [ -d tests ] && ls tests/test_*.py >/dev/null 2>&1; then \
		$(PYTHON) -m pytest -q tests; \
	else \
		echo "No Python tests yet"; \
	fi
