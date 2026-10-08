#!/usr/bin/env bash
# PreToolUse (Edit|Write): never touch Terraform state, provider caches or real tfvars.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')

case "$file" in
  *.tfstate|*.tfstate.*|*/.terraform/*|*.tfvars)
    echo "Blocked: $file is protected (state, provider cache or real variable values). Use a *.tfvars.example file instead." >&2
    exit 2
    ;;
esac
exit 0
