#!/usr/bin/env bash
set -euo pipefail

OWNER="${OWNER:-pccxai}"
DATE="$(date -Iseconds)"
OUT="reports/status-$(date +%Y%m%d-%H%M%S).md"

REPOS=(
  "pccx"
  "pccx-lab"
  "pccx-FPGA-NPU-LLM-kv260"
  "pccx-systemverilog-ide"
  "pccx-llm-launcher"
  ".github"
)

BLOCKED_REPOS=(
  "pccx-staging"
  "pccx-lab-staging"
  "pccx-FPGA-NPU-LLM-kv260-staging"
  "pccx-systemverilog-ide-staging"
  "pccx-llm-launcher-staging"
)

mkdir -p reports

{
  echo "# PCCXAI PM Assistant Status Report"
  echo
  echo "- Generated: $DATE"
  echo "- Actor: $(gh api user --jq .login)"
  echo "- Mode: read-report-only"
  echo
  echo "## Repository access"
  echo

  for repo in "${REPOS[@]}"; do
    perm="$(gh repo view "$OWNER/$repo" --json viewerPermission --jq .viewerPermission 2>/dev/null || echo "ERROR")"
    echo "- $OWNER/$repo: $perm"
  done

  echo
  echo "## Staging access check"
  echo

  for repo in "${BLOCKED_REPOS[@]}"; do
    if gh repo view "$OWNER/$repo" --json name >/dev/null 2>&1; then
      echo "- $OWNER/$repo: WARNING - accessible"
    else
      echo "- $OWNER/$repo: OK - not accessible"
    fi
  done

  echo
  echo "## Open pull requests"
  echo

  for repo in "${REPOS[@]}"; do
    echo
    echo "### $OWNER/$repo"
    gh pr list --repo "$OWNER/$repo" --state open --limit 20 \
      --json number,title,author,updatedAt,isDraft \
      --template '{{range .}}{{printf "- #%v %s | author=%s | draft=%v | updated=%s\n" .number .title .author.login .isDraft .updatedAt}}{{else}}- none{{end}}' \
      2>/dev/null || echo "- ERROR reading PRs"
  done

  echo
  echo "## Open issues"
  echo

  for repo in "${REPOS[@]}"; do
    echo
    echo "### $OWNER/$repo"
    gh issue list --repo "$OWNER/$repo" --state open --limit 20 \
      --json number,title,labels,updatedAt \
      --template '{{range .}}{{printf "- #%v %s | labels=" .number .title}}{{range .labels}}{{printf "%s," .name}}{{end}}{{printf " | updated=%s\n" .updatedAt}}{{else}}- none{{end}}' \
      2>/dev/null || echo "- ERROR reading issues"
  done
} > "$OUT"

echo "$OUT"
