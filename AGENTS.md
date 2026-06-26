# AGENTS.md

Conventions for engineers and AI assistants working in this repository
. Read this before making changes.

## How work flows

Branches map to environments and promote one direction only:
`feature/* -> dev -> staging -> main` (main is the production branch). Code should
not skip a stage or flow backward (except an explicit hotfix reconciliation), and
every change lands through a pull request. This is the team convention; it is
CI-enforced only when branch protection is configured (a paid-plan feature on
private repos).

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
  of the diff. The `create-pull-request` skill
  (`.claude/skills/create-pull-request/`) drafts one in the standard
  Problem / Goal / Scope / Verification format.
- **The security check should pass** before merge - secret-scan + Semgrep SAST.
  (On a paid plan you can make it a required check; the promotion flow below is a
  convention to follow, not a CI-enforced gate.)
- **Keep PRs small and focused** - one concern per PR; large PRs are hard to
  review safely.
- **Tests travel with code** - new behaviour should carry proportionate tests
  (a convention here, not an enforced gate; run your stack's test tool directly).

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
The Actions used here run on **Node.js 24**, so the runner host needs the GitHub
Actions runner agent **v2.327.1 or newer** (a freshly downloaded runner already
exceeds this); an older agent fails with a Node version error.

## First-time setup

Run `bash scripts/install-hooks.sh` once after cloning to activate the
secret-scanning pre-commit hook (or it runs via `make install`).
