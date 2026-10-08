#!/usr/bin/env bash
# PostToolUse (Edit|Write): run `terraform fmt` on any edited .tf/.tfvars file.
# Exit 2 sends a syntax error back to Claude so it fixes the file immediately.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
  *.tf|*.tfvars) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

if ! out=$(terraform fmt "$file" 2>&1); then
  echo "terraform fmt failed for $file:" >&2
  echo "$out" >&2
  exit 2
fi
exit 0
