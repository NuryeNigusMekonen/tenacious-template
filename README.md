# Project Template - User Guide

A GitHub template repository that gives every new project a secure-by-default
starting point. Click **"Use this template"** on GitHub to create a new
repository from it.

This single guide is everything you need to use the template end to end:
what it does, how to set it up, what to run, and the conventions to follow.

It is multi-language - `make install` auto-detects Python, JavaScript/TypeScript,
Go, Rust, and Java and installs the right dependencies for whatever your project uses.

---

## 1. What you get

| Area | What it does |
|------|--------------|
| **Secret scanning** | Blocks credentials (passwords, API keys, tokens) from being committed or pushed - at commit time, push time, and in CI. |
| **Security analysis** | Scans code for vulnerabilities with Semgrep static analysis on every pull request, behind a single `security` check. |
| **Code-quality checks** | Flag non-conventional PR titles, oversized pull requests, and duplicated code to keep changes reviewable (advisory). |
| **Dependency updates** | Dependabot opens weekly pull requests to bump outdated dependencies (`.github/dependabot.yml`). |
| **Reviewer assignment** | Requests the right reviewer when sensitive files change (`CODEOWNERS`). |
| **PR drafting skill** (optional) | The `create-pull-request` skill drafts a PR description in the standard format. See Section 7. |
| **Claude / Codex in your editor** (optional) | Ready MCP config lets Claude Code and OpenAI Codex talk to GitHub from this repo. Per-person, opt-in, no secret stored in the repo. See Section 8. |

---

## 2. How the branches work (convention)

The recommended flow is one direction, with no skipping. `main` is production.

```
feature/*  →  dev  →  staging  →  main (production)
```

| Branch | Receives from | Suggested reviews |
|--------|---------------|-------------------|
| `dev` | `feature/*`, `fix/*` | 1 |
| `staging` | `dev` | 1 |
| `main` | `staging` | 2 |

This is a **team convention**, not a CI-enforced gate. Enforcing it (required PRs,
required checks, required reviews) needs branch protection, which on a private repo
requires a paid plan - see Section 6. A shorter flow (e.g. `feature → dev → main`,
or trunk-based `feature → main`) is fine; just keep promotion one-directional.

---

## 3. The commands (Makefile)

You and the CI pipeline run the **same** commands, so local and pipeline
behaviour match. They auto-detect your language.

| Command | What it does |
|---------|--------------|
| `make install` | Install dependencies and activate the local secret-scanning hooks |
| `make sast` | Run Semgrep static analysis (the target CI also runs) |

If your project uses a language or layout the defaults don't cover, edit the
matching recipe in the `Makefile` - that is the intended place to adapt the
template to your project.

---

## 4. Set-up checklist (do these once per new repo)

1. **Create the repository** from this template ("Use this template" on GitHub).
2. **Run `make install`** once - installs dependencies and turns on the local
   secret-scanning hooks.
3. **Adjust the `Makefile`** commands for your stack if the defaults don't fit.
4. **Set your reviewers** - open `.github/CODEOWNERS` and replace the example
   names with your real team members or GitHub teams.
5. **On a paid plan, turn on branch protection** to make the `security` check
   required before merging - see Section 6. On a free private repo, follow the
   promotion flow as a convention instead.
6. When ready, **make the checks blocking** - the quality checks and Semgrep
   start advisory (they report but don't fail), so you can adopt them gradually
   and tighten when the baseline is clean.

---

## 5. Continuous integration

The workflows run automatically once the repo is on GitHub - there is nothing to
switch on. Every pull request and push gets: secret scanning, Semgrep static
analysis, the security gate, and the advisory quality checks (PR title, PR size,
duplicate code).

Secret scanning protects any codebase regardless of size, and runs on every project.

> **Runner requirement.** The workflows use `runs-on: self-hosted`, so a
> self-hosted GitHub Actions runner must be registered and online for the repo or
> org, with `git`, `bash`, `python3`+`pip`, `node`+`npx`, and `make` on its PATH.
> **Without a self-hosted runner the jobs queue forever.** If you want to use
> GitHub-hosted runners instead, replace `self-hosted` with `ubuntu-latest` in
> `.github/workflows/*.yml`.

---

## 6. Branch protection (paid plans only)

Branch protection is a GitHub setting, not a file. **Enforcing required checks and
required reviews on a private repo needs a paid plan** (GitHub Team or above);
GitHub Free for private repos cannot enforce them. This template therefore does
not ship a protection script - on a free private repo the promotion flow below is
a **convention the team follows manually**, not a CI-enforced gate.

If you are on a paid plan and want enforcement, apply a branch ruleset in
**Settings → Rules → Rulesets**: target `main` (and `dev`/`staging` if you use
them), and require a pull request, the `security` status check, force-push
protection, and conversation resolution.

---

## 7. How to work with the template (the everyday flow)

1. Cut a `feature/...` branch from `dev`.
2. Make your change; run `make sast` locally before pushing.
3. Commit - the secret hook checks for credentials automatically.
4. Open a pull request into `dev` (in Claude Code, the `create-pull-request`
   skill drafts the description in the standard format).
5. The automated checks run; address anything they flag.
6. Get it reviewed and merged.
7. Promote `dev → staging → main` through pull requests as the work matures.

---

## 8. Using Claude or Codex in your editor (optional)

This repo ships MCP configuration for both **Claude Code** and **OpenAI Codex**
so they can act on this repository through the **GitHub MCP server** - opening
pull requests, reading issues, checking CI, and so on, from plain-language
requests in your editor.

No secret is stored in the repo: `.mcp.json` and `.codex/config.toml` reference
a token by name only (`${GITHUB_FINE_GRAINED_TOKEN}` /
`GITHUB_FINE_GRAINED_TOKEN`). Never paste a real token into either file - it
would be committed and the secret scanner will flag it. Each person connects
with their **own** token, kept in their environment. To enable it:

1. Create a **fine-grained** Personal Access Token
   (GitHub - Settings - Developer settings - Fine-grained tokens):
   - **Repository access:** Only select repositories - pick this repo.
   - **Permissions:** Contents = Read and write, Pull requests = Read and write,
     Issues = Read and write, Metadata = Read (required). Add Workflows =
     Read and write only if you want the assistant to edit GitHub Actions files.
   - **Expiration:** set one (e.g. 90 days) - do not choose "no expiration".
   - Prefer this over a classic token: a fine-grained token is limited to the
     repos and permissions you grant, so a leak has a small blast radius.
   - If the repo is owned by an organization, an org admin may need to approve
     the token before it can reach the repo.
2. Put the token in your shell environment (not committed to any file). The
   name must match both MCP config files exactly - uppercase, no spaces:
   ```
   export GITHUB_FINE_GRAINED_TOKEN=your_token_here
   ```
3. For **Claude Code**, open the project. The first time, it asks you to
   **approve** the GitHub server defined in `.mcp.json` - approve it.
4. Verify Claude with `claude mcp list` - the `github` server should show
   connected.
5. For **Codex**, open the trusted project in the Codex CLI or IDE extension.
   Codex reads `.codex/config.toml`.
6. Verify Codex with `/mcp` in the Codex TUI or the IDE MCP panel - the
   `github` server should show connected.

The token only ever grants what you give it: a read-only token lets Claude or
Codex read the repo but not push or merge; the write permissions above are what
allow the assistant to open and manage pull requests. It can never exceed your
own GitHub access. If you want the MCP server itself to expose read-only tools,
change the MCP URL in both config files to:

```
https://api.githubcopilot.com/mcp/readonly
```

This is per-person and entirely optional. Nothing else in the template depends
on it; the CI workflows and checks run regardless of whether you use it.

---

## 9. Standard formats

### Commit / pull-request titles

Titles follow a simple prefix format. This keeps history readable and
consistent (and the PR-title check warns when a title doesn't match).

```
<type>: short summary

types:
  feat:     a new capability
  fix:      a bug fix
  feat!:    a breaking change
  chore:    maintenance
  docs:     documentation only
  refactor: code change, no behaviour change
  test:     tests only
```

Examples:
```
feat: add password reset
fix: correct cart total with discounts
feat!: change the report export format
```

### Pull-request description (recommended)

Every pull request should answer (the `create-pull-request` skill drafts this for you):
- **What changed and why** - in plain language, not a restatement of the diff.
- **Related task / issue** - a link.
- **How it was verified** - what you ran or checked.
- **Risk & scope** - does it touch sensitive areas (auth, data, billing)?

### Bug report (recommended)

- What happened, and what you expected.
- Steps to reproduce.
- Branch / environment and version.
- Logs or screenshots (never paste secrets).

---

## 10. Good to know

- **Security and quality checks start advisory** - they report problems but
  don't block merges at first, so you can adopt them gradually and tune out
  false positives, then make them blocking when ready.
- **Local hooks activate with `make install`** (once per machine). The CI
  secret scan always runs as a safety net regardless.
- **If a real secret ever reaches the repository, rotate it** (change the
  credential) - removing it from history is not enough.
