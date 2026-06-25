# AGENTS.md

Conventions for engineers and AI assistants working in this repository
. Read this before making changes.

## How work flows

Branches map to environments and promote one direction only:
`feature/* -> dev -> staging -> main` (main is the production branch). Code never skips a stage or flows
backward (except an explicit hotfix reconciliation). Every merge into a
protected branch goes through a pull request.

## Before you open a PR

1. Does the change match the requirement? (re-read the ticket/acceptance criteria)
2. Does it introduce risk outside its stated scope? (auth, shared utils,
   migrations, billing, PII, prompts get stricter scrutiny)
3. Is it maintainable by someone who has never seen it?
4. Do the tests prove what they claim? (fail when behaviour breaks)

## Hard rules

- **No secrets in the repo.** No credentials, tokens, or keys in source, config,
  diffs, or logs. Use env vars / a secrets store. Example config lists variable
  names with placeholder values only. The pre-commit hook + CI scan enforce this.
- **Every PR has a real description** - what changed and why, not a restatement
  of the diff (use the PR template).
- **Required checks must pass** before merge - security (secret-scan) and branch-flow.
- **Keep PRs small and focused** - one concern per PR; large PRs are hard to
  review safely.
- **Tests travel with code** - new behaviour should carry proportionate tests
  (a convention here, not an enforced gate; run your stack's test tool directly).

## AI-powered testing

When you want thorough coverage for a feature - not a single quick test - use the
`ai-powered-testing` skill (`.claude/skills/ai-powered-testing/`). It runs a
layered, language-agnostic flow: one AI writes the unit/integration/E2E pyramid, a
**second fresh-context AI** reviews it for vanity tests and weak assertions, and an
optional **third** tries to break the feature with inputs the spec didn't
anticipate. A single AI grading its own tests is a weak signal; the fresh context is
the point. In Claude Code it auto-activates on prompts like "test this feature
properly" or "have a second AI look at these tests".

## Commands

The `Makefile` is the single command surface: `make install` (deps + hooks) and
`make sast` (the target CI also runs). Secret scanning runs via
`scripts/secret-scan.sh` directly (git hooks + CI).

## CI runner

All workflows run on a **self-hosted runner** (`runs-on: self-hosted`), not
GitHub-hosted VMs. Unlike a fresh `ubuntu-latest` VM, the runner persists state
between jobs and is **not** pre-loaded with tooling, so the host must have these
on `PATH`: `git`, `bash`, `python3` + `pip`, `node` + `npx`, and `make`. If a
job fails with "command not found", install the missing tool on the runner host.

## First-time setup

Run `bash scripts/install-hooks.sh` once after cloning to activate the
secret-scanning pre-commit hook (or it runs via `make install`).
