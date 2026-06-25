---
name: create-pull-request
description: Create a GitHub pull request for the current branch in the repo's standard format (Problem / Goal / Scope / Verification Steps), respecting the feature → dev → staging → main branch flow. Use when the user wants to open a PR, raise a PR, or "PR this branch".
---

# create-pull-request

Open a GitHub pull request for the current branch, with a body in the standard
**Problem / Goal / Scope / Verification Steps** format. Respects this repo's
promotion flow: `feature/* → dev → staging → main` (see `.github/branch-flow.yml`).

## Usage

```
/create-pull-request
/create-pull-request <free-text description of the change>
/create-pull-request --base <branch>
/create-pull-request --draft
```

Omitting arguments triggers interactive mode — you'll be prompted for each required section.

## Inputs you must collect (read-only first, then ask)

Before asking the user anything, gather what `git` can tell you. Do **not** ask the user for things you can read from the working tree.

1. **Current branch**: `git branch --show-current`. If it is a protected branch (`main`, `dev`, `staging`), stop and ask the user to switch to a `feature/*` (or `fix/*`/`hotfix/*`) branch first.
2. **Base branch**: detect with this priority order:
   - Explicit `--base <branch>` argument if the user passed one.
   - Otherwise default to **`dev`** — the standard target for `feature/*`/`fix/*` work in this template. (For a `hotfix/*` branch, propose `main`.)
   - Confirm the resolved base with the user before pushing.
3. **Commits ahead of base**: `git log --pretty=format:'%h %s' <base>..HEAD`. Use these to seed the title and the In-scope bullets.
4. **Changed files**: `git diff --stat <base>...HEAD`. Use this to suggest scope and verification steps. Detect the stack from the changed paths and the repo, the same way the `Makefile` does (Python/JS-TS/Go/Rust/Java), and suggest the matching test command (e.g. `pytest <path>`, `npm test`, `go test ./...`, `cargo test`).
5. **Remote tracking**: `git status -sb` and `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null`. You'll need to know whether to use `git push` or `git push -u origin <branch>`.
6. **Issue/ticket from branch name**: if the branch name contains an issue key or number (e.g. `123-…`, `JIRA-456-…`), note it for the body. Put it on a reference line in the body, not in the title.
7. **Uncommitted changes**: `git status --porcelain`. If anything is dirty, surface the list and ask whether to (a) commit-then-PR, (b) stash, or (c) abort.

## Title format

Use the Conventional-Commit format the repo's PR-title check expects:

```
<type>: <imperative summary>
```

- `type` is one of: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `perf`.
- Imperative mood (`add X`, not `added X` or `adds X`).
- Under 70 characters.
- No marketing words: `improve`, `enhance`, `better`, `robust`, `clean up`.
- An issue/ticket key goes in the body, not in the title.

Infer the `type` from the changes:
- New behaviour or new file users will interact with → `feat`
- Bug fix → `fix`
- Doc-only change → `docs`
- Tests-only change → `test`
- Performance work with measurements → `perf`
- Code reorg with no behaviour change → `refactor`
- Tooling, config, deps, CI → `chore`
- A breaking change → append `!` (e.g. `feat!:`)

If the diff straddles categories, pick the one the reviewer will care about most and mention the others in **In scope**. If you genuinely can't tell, ask.

## Body — section-by-section authoring rules

Assemble the body from these sections **in this exact order**. Omit any section whose content is genuinely empty; do not include a section with a placeholder. **Never write `N/A` or `None` under a heading — delete the section instead.**

### Reference line (top of body, optional)

If the branch name carries an issue/ticket key, or the user names a linked GitHub issue, emit a reference at the very top:

- GitHub issue: `Closes #123`
- External tracker: `Tracker: <KEY>` (link it if the user gives a URL)

If there's no key and the user has none to add, omit this line — do not write `Closes #` with a blank number.

### `## Context` (optional)

Ask: "Is there motivation a reviewer needs that isn't visible in the diff (incident, audit finding, stakeholder ask)?"

- 1–3 sentences. If the user has nothing to add, **delete the section entirely.**

### `## Problem`

Required. Ask: "What is broken, missing, or wrong? For bugs, include the mechanism (error, log line, failing behaviour) — not just 'it didn't work'."

- 1–4 sentences. If the change is purely additive, reframe as the gap the feature fills.

### `## Goal`

Required. Ask: "What does the end state look like after this PR merges? Describe the result, not the process."

- 1–2 sentences.

### `## Scope`

Required. Pre-fill **In scope** from the diff (one bullet per substantive change — group trivial edits). Ask the user to confirm and add anything you missed. Then ask: "Anything a reviewer might expect but you intentionally skipped?" — add an **Out of scope** bullet with a one-line reason for each. If nothing was skipped, delete the **Out of scope** block.

```
**In scope**
- <change 1>
- <change 2>

**Out of scope**
- <thing> — <reason, e.g. "follow-up in #123">
```

### `## Verification Steps`

Required. Mix automated and manual checks.

- `[x]` = already verified — include the command run or evidence captured (test count, output snippet).
- `[ ]` = still to verify, typically staging/prod checks.

Do **not** list "code review passes" or "CI green" — those are table stakes. **Only list checks the user actually performed or genuinely plans to perform.** If tests changed, suggest a line like `[x] pytest <path> — N passed` (or the stack's equivalent) and ask the user to confirm the result. If no tests changed, do not invent a verification line.

### `## Screenshots` (optional)

Only include if UI files changed (`*.html`, `*.erb`, `*.tsx`, `*.jsx`, `*.vue`, CSS, or a front-end directory). Otherwise delete the section entirely. If UI did change, ask the user to drop the screenshot URL or note "to attach in GitHub" — do not invent image URLs.

## Workflow

1. **Gather** all read-only context above. Cache it for the rest of the session.

2. **Pre-flight checks** (block on failure):
   - On a non-protected branch (not `main`, `dev`, or `staging`).
   - The source → base direction is legal under `.github/branch-flow.yml` (e.g. `feature/* → dev`, `dev → staging`, `staging → main`). If the chosen base would violate the flow, warn and ask before continuing — the `branch-flow` CI check will fail it otherwise.
   - Working tree clean OR user explicitly chose to commit first / proceed with stash.
   - At least one commit ahead of the base branch.

3. **Draft** the title and body using the rules above. **Do not call `gh pr create` yet.**

4. **Preview**: print the full title and body to the user exactly as they will appear on GitHub. Ask: "Submit, edit, or cancel?"

5. **On `edit`**: ask which section to edit, take the new content, re-print the full preview, ask again.

6. **On `submit`**:
   - If the local branch has no upstream: `git push -u origin <branch>`.
   - Else if there are unpushed commits: `git push`.
   - Create the PR. Use a HEREDOC for the body to preserve exact formatting:

     ```bash
     gh pr create \
       --base "<base>" \
       --title "<title>" \
       --body "$(cat <<'EOF'
     <full body here>
     EOF
     )"
     ```

   - If `--draft` was requested, append `--draft`.

7. **Report** the PR URL on stdout. Do **not** auto-open the browser, do **not** post the link anywhere else.

## Rules

- **Never fabricate** verification steps, screenshots, or scope bullets. If the user hasn't done something, don't claim they did.
- **Never write `N/A` or `None`** under a section heading — delete the section instead.
- **Never amend or force-push** to fix a typo discovered after preview but before submit — re-render and re-confirm instead.
- **Never push to `main`, `dev`, or `staging` directly.** The skill only operates on non-protected branches and respects the promotion flow.
- **Never use `--no-verify`.** If a pre-push hook (the secret scanner) fails, surface the failure to the user and stop — do not bypass it.
- Do not skip the preview-and-confirm step, even if the user passed the entire description as an argument.
- If `gh pr create` fails (auth, network, base-branch missing), print the exact error and ask the user how to proceed rather than retrying blindly.

## Worked example

Branch: `feature/parameterise-sql`
Base: `dev`
Commits ahead: 2 (`quote identifiers in FilterRuleUpdater`, `add regression test`)
Changed files: `src/context_data/filter_rule_updater.py`, `tests/context_data/test_filter_rule_updater.py`

Resulting title:

```
fix: parameterise SQL in FilterRuleUpdater
```

Resulting body:

```
## Problem

`FilterRuleUpdater` interpolated column names and values directly into raw SQL.
An admin who can edit a filter rule's updates can inject arbitrary SQL.

## Goal

Column identifiers are quoted; values are bound as parameters. Query semantics
are preserved exactly — same rows matched, same writes.

## Scope

**In scope**
- Quote table + column identifiers in the update path
- Bind values as parameters instead of string interpolation
- Regression test covering a malicious updates value

**Out of scope**
- Static-analysis config updates — follow-up once these call sites stop being flagged

## Verification Steps

- [x] `pytest tests/context_data/` — 45 passed
- [ ] Confirm the SAST check no longer flags these call sites in CI
```

(No `## Context` — the Problem already explains the motivation. No `## Screenshots` — no UI files changed.)
