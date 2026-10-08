#!/usr/bin/env bash
# PreToolUse (Bash): block commands that change real AWS infrastructure or state,
# and pushes to main (main only changes through a reviewed pull request).
set -uo pipefail

cmd=$(jq -r '.tool_input.command // empty')

if printf '%s' "$cmd" | grep -Eq 'terraform([[:space:]]+-[^[:space:]]+)*[[:space:]]+(apply|destroy)\b'; then
  echo "Blocked: 'terraform apply/destroy' is not allowed from Claude in this repo. Run it yourself after reviewing the plan." >&2
  exit 2
fi

if printf '%s' "$cmd" | grep -Eq 'terraform([[:space:]]+-[^[:space:]]+)*[[:space:]]+state[[:space:]]+(rm|mv|push|replace-provider)\b'; then
  echo "Blocked: changing Terraform state is not allowed from Claude in this repo." >&2
  exit 2
fi

if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push\b'; then
  branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null)
  # Only inspect the push itself, not other commands chained after it (e.g. gh pr create --base main).
  push_args=$(printf '%s\n' "$cmd" | grep -Eo 'git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push[^;&|]*')
  if printf '%s' "$push_args" | grep -Eq '([[:space:]:/+])(main|master)([[:space:]]|$)' || [ "$branch" = "main" ]; then
    echo "Blocked: never push to main. Push a feature branch and open a pull request; only the repo owner merges." >&2
    exit 2
  fi
fi

if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+merge\b'; then
  echo "Blocked: only the repo owner merges pull requests. Share the PR link instead." >&2
  exit 2
fi

exit 0
