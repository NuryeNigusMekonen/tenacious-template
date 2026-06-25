# AI PR Review (admin, via GitHub MCP)

A free, on-demand way for an admin to get a standardized professional code review
posted onto a pull request - using an AI chat connected to GitHub over MCP. No
Copilot subscription, no API key, no workflow cost. The admin triggers it; the AI
reads the PR diff and posts review comments.

> This is **manual / on-demand**, not automatic-on-PR. MCP runs inside the admin's
> AI chat, not on GitHub's servers, so there is no "review every PR automatically"
> mode here. The admin runs it when they choose.

---

## Prerequisites

- An AI chat client (e.g. Claude Desktop / Claude Code) with the **GitHub MCP
  connection** configured and authenticated as a user with write access to the repo.
- The repo's `owner/name` and the PR number.

## How to run a review

In the admin AI chat, paste the **standard review prompt** below, filled in with the
repo and PR number. The AI will read the diff and post a single structured review.

> Review pull request `<owner>/<repo>#<number>` and post a review.

That's the trigger. The standard prompt that follows defines *how* it reviews, so the
output is consistent every time.

---

## Standard review prompt (copy/paste, fill the blanks)

```
Review pull request <owner>/<repo>#<NUMBER> and post a single COMMENT review.

Use these steps:
1. Read the PR: title, description, the diff, and the list of changed files.
2. Review against this standard, in order. For each finding, reference the file
   and line, and keep the tone professional and specific - no vague praise.

   a. Correctness   - logic errors, edge cases, off-by-one, unhandled errors.
   b. Security      - injection, unsafe input, secrets in code, broken authz.
   c. Tests         - is changed behaviour covered? (flag if not, do not block).
   d. Readability   - naming, dead code, duplication, oversized functions.
   e. Convention    - Conventional-Commit PR title, scope creep vs description.
   f. Risk          - touches auth/data/migrations/billing/shared utils/prompts?

3. Post the review as a COMMENT (not APPROVE, not REQUEST_CHANGES) unless I say
   otherwise. Open with a 2-3 line summary, then a short bulleted list of findings
   grouped by the categories above. If nothing is wrong in a category, omit it.
   End with the single most important thing to address.

4. Do NOT merge, close, label, or change the PR. Review only.
```

### Notes on the prompt
- **COMMENT by default** - the AI advises; a human still decides to approve/merge.
  Change step 3 if you want it to `REQUEST_CHANGES` on real problems.
- **Review only** (step 4) - the admin chat has write access, so the prompt explicitly
  forbids merge/close/label to prevent the AI from acting beyond review.
- **Tune the standard** (step 2) to your team - add or drop categories.

---

## What the AI uses under the hood (for reference)

| Step | MCP tool |
|------|----------|
| Read the diff / files / existing reviews | `pull_request_read` (get_diff, get_files, get_reviews) |
| Post the review | `pull_request_review_write` (method: create, event: COMMENT) |
| Reply to an existing comment thread | `add_reply_to_pull_request_comment` |

## Do / Don't

**DO**
- Run it from an admin chat **before** requesting human review - it catches the
  obvious issues so humans focus on judgement calls.
- Keep the standard prompt in this file as the single source of truth, so every
  review checks the same things.

**DON'T**
- Don't treat it as a required gate - it is advisory, posted from a chat, and not
  guaranteed to run on every PR. The required gates remain `security` and `branch-flow`.
- Don't let it merge or approve on its own - keep step 4 in the prompt.
- Don't expect it to run unattended - if you need automatic-on-every-PR review, that
  needs a server-side AI (Copilot subscription or an LLM-API workflow), which this is not.
