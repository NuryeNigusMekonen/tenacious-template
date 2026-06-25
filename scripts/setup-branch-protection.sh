#!/usr/bin/env bash
# Create dev + staging and apply branch protection (PR-only, passing checks,
# code-owner review, no force-push/delete; main needs 2 approvals, dev/staging 1).
# Run once per repo. Idempotent.
#
# Requires gh authenticated with repo admin rights (gh auth login).
# Usage: scripts/setup-branch-protection.sh <owner/repo>
#
# NOTE: GitHub protection can't reject a wrong-source merge (e.g. dev -> main);
# the branch-flow job in governance.yml enforces direction on PRs.
set -euo pipefail

REPO="${1:?usage: setup-branch-protection.sh <owner/repo>}"
DEFAULT="$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)"

# 1. Create dev + staging off the default (production) branch.
base_sha="$(gh api "repos/${REPO}/git/refs/heads/${DEFAULT}" -q .object.sha)"
for b in dev staging; do
  if gh api "repos/${REPO}/git/refs/heads/${b}" >/dev/null 2>&1; then
    echo "branch '${b}' already exists - skipping create."
  else
    gh api -X POST "repos/${REPO}/git/refs" \
      -f "ref=refs/heads/${b}" -f "sha=${base_sha}" >/dev/null
    echo "created branch '${b}'."
  fi
done

# 2. Protect each branch. Required checks = security + branch-flow; the quality
# jobs stay advisory (not required) on purpose.
CONTEXTS='["security", "branch-flow"]'
echo "Requiring checks: security + branch-flow."

protect() { # $1 = branch, $2 = required approvals
  local branch="$1" approvals="$2"
  echo "protecting '${branch}' (require ${approvals} approval(s)) ..."
  # JSON body (not -f/-F) so field types stay correct - the API rejects strings.
  cat <<JSON | gh api -X PUT "repos/${REPO}/branches/${branch}/protection" \
      -H "Accept: application/vnd.github+json" --input - >/dev/null
{
  "required_status_checks": {
    "strict": true,
    "contexts": ${CONTEXTS}
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": ${approvals},
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
}

# main IS production (the default branch). Flow: feature -> dev -> staging -> main.
protect main 2                # production (main): Tech Lead + Project Owner
protect dev 1                 # feature -> dev: automated checks + 1 review
protect staging 1             # dev -> staging: Tech Lead review

echo ""
echo "Done. main (production) protected; dev / staging created and protected."
echo "Reminder: the directional rule (no skipping, no backward flow) is"
echo "enforced on pull requests by the branch-flow job in .github/workflows/governance.yml."
