#!/usr/bin/env bash
# Validate every module against the LOWEST AWS provider version it claims to support.
# `terraform init` normally picks the newest provider, which hides features missing
# from older ones (this caught budget tags and python3.13 not existing before 5.80).
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "${tmp:?}"' EXIT

status=0
for dir in "$root"/modules/*/; do
  name=$(basename "$dir")
  floor=$(grep -A2 'source *= *"hashicorp/aws"' "$dir/versions.tf" | sed -nE 's/.*version *= *">= *([0-9.]+)".*/\1/p')
  if [ -z "$floor" ]; then
    echo "!! $name: no '>= x.y' AWS provider constraint found in versions.tf"
    status=1
    continue
  fi

  work="$tmp/$name"
  mkdir -p "$work"
  cp "$dir"/*.tf "$work/"
  [ -d "$dir/lambda" ] && cp -R "$dir/lambda" "$work/"
  sed -i.bak -E "s/(version *= *)\">= *$floor\"/\1\"= $floor\"/" "$work/versions.tf"

  if terraform -chdir="$work" init -backend=false -input=false >/dev/null 2>&1 &&
     terraform -chdir="$work" validate -no-color >/dev/null 2>&1; then
    echo "ok $name (aws = $floor)"
  else
    echo "FAIL $name (aws = $floor)"
    terraform -chdir="$work" validate -no-color 2>&1 | sed 's/^/   /' | head -20
    status=1
  fi
done

exit $status
