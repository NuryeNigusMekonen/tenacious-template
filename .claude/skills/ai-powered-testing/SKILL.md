---
name: ai-powered-testing
description: Run the layered AI-powered testing workflow on a feature — generate a unit/integration/E2E test pyramid, have a second fresh-context AI agent review the suite for vanity tests and weak assertions, optionally do exploratory testing to try to break the feature, and promote the interesting findings into permanent tests. Use whenever the user wants comprehensive tests for a feature, says things like "test this feature properly", "AI-powered testing", "write tests with a second opinion", or asks for exploratory/breakage testing on top of normal coverage. Prefer this skill over ad-hoc test-writing whenever the user signals they want thorough coverage rather than a single quick test.
---

# ai-powered-testing

A layered testing workflow. Six steps, two reports.

The point of this workflow is that **a single AI writing tests against its own implementation is a weak signal**. The same model that built the feature is the wrong reviewer of the tests for that feature — it tends to write tests that pass for the same reasons the code passes, miss the edge cases it didn't think of while building, and confuse "the code runs" with "the code is correct." So we layer:

1. One AI generates the suite.
2. A **second, fresh-context AI** reviews the suite for the things the first one was blind to.
3. A **third, fresh-context AI** tries to break the feature with inputs the spec didn't anticipate.

Fresh context is load-bearing. Don't try to do step 2 or step 4 in the same conversation that wrote the tests — spawn a subagent (`Agent` tool) so the reviewer/breaker comes in cold.

## When this skill triggers

- "Write tests for the feature on this branch"
- "Test this feature properly — unit, integration, end-to-end"
- "AI-powered testing on PR #1234"
- "Have a second AI look at these tests"
- "Try to break this feature"

If the user just wants a single test for a single function, that's plain test-writing — don't drag them through this whole flow. Ask if you're unsure whether they want the full pyramid.

## Inputs to gather before starting

Before step 1, you need to know:

1. **What feature is being tested?** Usually the diff on the current branch, sometimes a specific set of files, sometimes a feature description in a ticket. Confirm with the user. If it's "the current branch", run `git diff <base>...HEAD --stat` and pre-fill the scope.
2. **Where do the tests live, and what framework?** This template is multi-language — **read the repo, don't guess.** Detect the stack the same way the `Makefile` does and follow the conventions already in the tree:
   - **Python** — `tests/` or `test_*.py`, usually `pytest` (sometimes `unittest`).
   - **JavaScript / TypeScript** — `__tests__/` or `*.test.ts` / `*.spec.ts`, usually `jest` / `vitest`; E2E often `playwright` / `cypress`.
   - **Go** — `*_test.go` colocated with the package, run with `go test`.
   - **Rust** — `#[cfg(test)]` modules and `tests/`, run with `cargo test`.
   - **Java** — `src/test/java`, usually JUnit, run with `mvn test` / `gradle test`.
   - If the repo has a `CLAUDE.md`/`AGENTS.md` or existing test directory, its conventions win over these defaults.
3. **Where does end-to-end live?** Default to **this repo** (a request/integration test colocated with the app). Propose a separate test-automation repo only when the feature spans services or the team owns a cross-cutting browser-driven suite elsewhere. **Ask the user once, up front** — then pick a location and stick to it for this run.
4. **What does "green" mean?** The exact command the user expects to run at the end (e.g. `pytest tests/foo/`, `npm test`, `go test ./...`, `cargo test`). Capture this early because step 6 needs it.

## Step 1 — Generate the test pyramid

Goal: produce a first-pass unit, integration, and end-to-end suite for the feature.

- Read the feature code first. Do not write tests from the ticket description alone — the code is the source of truth for what currently exists; the ticket tells you what *should* exist. The gap between them is exactly what the tests need to cover.
- Match the repo's existing test patterns. If specs use fixtures, builders, or factories, your new tests should too. Inconsistency in test style makes the suite harder to maintain and signals that the tests weren't written by someone who reads the codebase.
- **Unit tests**: one behaviour per test. Cover happy path, the obvious edge cases (null/none, empty, boundary), and the error paths the code explicitly handles. Don't test framework or library behaviour unless your code adds logic on top.
- **Integration tests**: cover the seams — the controller/handler hitting the response plus side effects (DB rows written, jobs enqueued, messages published, files written). For multi-service work, cover the contract between services.
- **End-to-end tests**: one or two journey-level tests through the UI or public API end-to-end. Don't try to cover every branch here — that's what unit/integration are for. E2E catches "the wiring is wrong."

If the user picked a separate automation repo for E2E, do unit + integration in this repo and write the E2E test there. State clearly which repo each new file goes in. If that repo isn't cloned locally, ask the user where it is or whether to add the E2E later.

Write the tests. Run them. **They must be green before you go to step 2.** A red suite is a much weaker signal for the reviewer in step 2 — they'll spend attention on the failures instead of on the things that matter (assertions, coverage, vanity tests).

## Step 2 — Second-AI review (fresh context)

Goal: have a separate agent, with no memory of how the tests were written, read the suite cold and flag what's weak.

Spawn a subagent via the `Agent` tool. Give it:

- The path(s) to the test files you just wrote.
- The path(s) to the feature code under test.
- The acceptance criteria / ticket description if you have it.
- An explicit instruction to look for, specifically:
  - **Coverage gaps** — branches in the code that no test exercises, error paths that aren't asserted on, edge cases the spec implies but no test covers.
  - **Vanity tests** — tests that look like coverage but don't actually constrain behaviour (e.g. asserting a value is "present" when any non-null value passes; asserting status `200` with no assertion on the body).
  - **Weak assertions** — assertions that would pass even if the code were subtly wrong (e.g. asserting an array is non-empty instead of asserting its contents; checking a record exists instead of checking its fields).
  - **Tests that pass for the wrong reasons** — tests where the setup doesn't actually reach the code path being claimed (e.g. a test "for the admin permission path" where the user is also the record owner, so it passes via a different branch).
  - **Over-mocking** — so much of the system mocked that the test no longer constrains real behaviour.

Tell the subagent **not** to rewrite anything — it should produce a structured list of findings, each with: file:line, what's wrong, why it's wrong, and the suggested action (strengthen / delete / replace).

When the subagent reports back, present the findings to the user as the **test-review report** (see "Reports"). Walk through each finding and decide together: strengthen, delete, replace, or deliberately leave alone (with a reason).

## Step 3 — Act on the review

Apply the agreed-on changes. Re-run the suite. Green again.

Keep a running list of:
- Findings acted on (and how).
- Findings deliberately left alone (and why — this matters for the report).

This list becomes the body of the test-review report.

## Step 4 — Exploratory testing: try to break the feature (fresh context, optional)

**Ask the user before running this step.** Exploratory testing is the most expensive part of the workflow — it spawns another subagent, runs the feature with novel inputs, and produces a report the user then has to triage. For small, low-risk changes it's often overkill; for anything touching money, auth, data integrity, or external integrations, it's usually worth it. Don't decide for the user — surface the trade-off and ask.

Phrase the ask concretely, e.g.: "Want me to run the exploratory pass? It'll spawn a fresh agent to try to break <feature> with inputs the spec didn't anticipate, and produce a list of findings to triage. Worth it if you're worried about edge cases; skippable if the change is mechanical." Default to **yes** if the user gave any signal they want it (e.g. they used "exploratory", "try to break", "edge cases"); default to **ask** otherwise.

If the user says skip, jump to step 6 and say explicitly that the exploratory report was intentionally omitted, not forgotten.

If the user says go, spawn another subagent. Give it:

- A description of the feature (what it's supposed to do).
- The entry points (URL, function signature, CLI command — whatever the user-facing surface is).
- Permission to run the feature, manipulate inputs, read logs and state, and otherwise probe.
- An explicit instruction: **assume the spec is incomplete**. Look for inputs the spec didn't anticipate — boundary values, empty/very-large inputs, concurrent calls, unicode, malformed payloads, permission edges, state interactions (what happens if you call this twice? In a different order? After deleting a dependency?).

Tell the subagent to produce a structured report: each finding has a reproducer (concrete inputs/commands), the observed bad behaviour, and a hypothesis for the root cause.

Some findings will be bugs (real defects). Some will be "not bugs but tests we should have" (behaviour that's defensible but underspecified). Some will be noise.

## Step 5 — Promote interesting findings into permanent tests

(Skip this step if step 4 was skipped.)

For each exploratory finding, decide with the user:

- **Bug** — file it, optionally fix it now if scope allows. Add a regression test that fails on the unfixed code.
- **Underspecified behaviour worth pinning down** — add a permanent test that locks the current behaviour in. Note in the test why this case matters.
- **Noise** — drop it, but note in the report that you considered and rejected it (so a reader knows you didn't just miss it).

Re-run the suite. Still green.

## Step 6 — Run the suite end-to-end

Run the full suite the user identified up front ("what does green mean?"). Capture the count, pass/fail summary, and runtime. Include this in the final wrap-up.

**Out of scope for this skill: updating the PR description.** Once the suite is green and the reports are ready, the user can take the reports into a PR update separately (see the PR description format in `README.md` / `AGENTS.md`).

## Reports

Both reports are produced as **plain text output in the conversation**, not files. The user can ask for them as documents (e.g. "save these to Doc/testing/feature-x.md") and you can write the file then — default is in-session only.

### Test-review report

Use this exact structure:

```
# Test-review report — <feature name>

## What the reviewer flagged
For each finding from step 2:
- **<file:line>** — <one-line summary of the issue>
  - Why it's weak: <one or two sentences>
  - Action taken: <strengthened / deleted / replaced / left alone>
  - <If left alone>: Reason — <why this is deliberate>

## What changed
- <count> tests strengthened
- <count> tests deleted
- <count> tests replaced
- <count> findings left alone (see above)

## What the reviewer missed
(Optional — only fill in if, during step 4 or step 5, you realised the reviewer should have caught something but didn't. This is a signal for tuning the review prompt next time.)
```

### Exploratory testing report

Use this exact structure:

```
# Exploratory testing report — <feature name>

## What broke (or surprised us)
For each finding from step 4:
- **<short title>** — <one-line summary>
  - Reproducer: <concrete inputs / steps>
  - Observed: <what actually happened>
  - Verdict: <bug / underspecified behaviour / noise>
  - Resolution: <filed as <ticket>, fixed in this PR, pinned with a new test at <file:line>, dropped because …>

## New permanent tests added
- <file:line> — <what this test pins down, and which exploratory finding it came from>

## Open questions for the team
(Optional — anything the exploratory pass surfaced that the team should think about beyond this PR. Architectural smell, missing observability, ambiguous spec.)
```

Keep both reports tight. The reader is a teammate reviewing the PR — they want to see what the layered AI review caught and what the team chose to do about it, not a wall of methodology.

## A few notes on running this skill well

- **Don't skip subagents to save tokens.** Fresh context is load-bearing for both the review pass and the exploratory pass — that's the whole reason this workflow exists. Running the "second AI" in the same conversation that wrote the tests gets you almost none of the value.
- **Step 4 is user-gated because it's expensive, not because the subagent is optional once approved.** The gate exists so the user can opt out of the exploratory pass entirely on small/low-risk changes. It is **not** an opening to run the exploratory pass in the main thread to save time.
- **Don't let the reviewer subagent rewrite tests.** It produces findings; the team (with you as the main agent) decides what to do.
- **Be honest in the reports.** If you left a finding alone because the user said "skip it" or because acting on it was out of scope, say so. The report's job is to make the reasoning visible, not to make the suite look airtight.
- **The exploratory pass is allowed to find nothing interesting.** That's a valid outcome. Say so instead of inventing findings.
- **Match the repo's conventions over these defaults.** If `CLAUDE.md`/`AGENTS.md` or an existing test directory documents how this project tests, follow that.
