# Pull-request guide

A reference for what a good PR covers and **why** - not a form you must fill in.
The actual PR template (`.github/pull_request_template.md`) is intentionally
short; pull from this guide for the parts that apply to your change, and ignore
the rest.

> Adapt the bracketed placeholders (`[…]`) to your org's links - other-service
> repos, changelog files, docs space, review channel.

---

## Description

Describe what you did, in plain language. The title and commit-message bodies
should explain *what features are getting added or changed* and why - not just
restate the diff. (Good commit hygiene: <https://chris.beams.io/posts/git-commit/#seven-rules>.)

## PR dependencies

Add links to any PRs this one depends on.

**Does deploying this code depend on deploying another service?**
If yes, link the other service's PR in the description. A reviewer needs to know
the deploy order, or shipping this alone breaks production.

## Testing instructions

Describe how to verify what you did - the steps a reviewer can follow to confirm
it works. Update or write tests for the relevant parts of your code where the
project has a test suite; tests are what stop a future change from silently
breaking this one.

## Reviewers & docs

- Post the PR to your team's review channel (e.g. `[#pull-requests on Slack]`)
  and tag the reviewers, so it doesn't sit unseen.
- If the change needs explaining beyond the code, write it up in your docs space
  (e.g. `[Confluence]`) and link it - the next person shouldn't have to
  reverse-engineer the reasoning.

## Backend changes

- **Changed the API?** Update the API changelog (e.g. `[API_CHANGELOG.md]`) so
  consumers can see what moved.
- **Added an endpoint?** Update the feature config (e.g. `[config/features.yml]`)
  and label the PR, so the new surface is tracked and gated.
- **Added a background/rake task?** Put it in the tasks directory and document it
  where your team lists tasks - undocumented tasks get lost.

## Frontend changes

- **New page or UI element?** Put it behind a permission/feature flag, so it can
  be rolled out (or rolled back) without a code change.

---

When in doubt, say more in the description rather than less - the reviewer's time
is cheaper than a wrong assumption shipped to production.
