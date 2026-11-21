---
name: rate-my-pr
description: Grade a pull request, branch, or diff on a 1-5 star scale across scope, correctness, test coverage of the change, diff quality, commit hygiene, and reviewability. Produces a scorecard with blocking issues and ID'd fixes. Use when the user asks to rate, grade, score, or review a PR, MR, branch, or set of changes before merging.
---

# Rate My PR

Grade a change, not a codebase. The question is **"should this merge?"**, not "is this
repo good?". Pre-existing debt the PR merely touches is not the PR's fault — say so and
move on.

**This skill never edits code.** It writes only its own report and history row under
`.rate-my-code/`. Fixing is a separate step (see [Hand off](#6-hand-off)).

<!-- shared:untrusted-code -->
**Untrusted code:** running a project's tests, build, or scripts executes that project's
code. If the user did not write the repository or does not trust it, ask before running
anything. Without a yes, review statically and list the skipped checks in the report.
<!-- /shared:untrusted-code -->

## 1. Get the diff

In order of preference:

1. A PR number or URL the user gave — fetch it with `gh pr view <n> --json title,body,files,commits`
   and `gh pr diff <n>` (or the GitLab/Bitbucket equivalent).

   **No `gh`, or not logged in?** Use another GitHub integration you have if one exists.
   Otherwise fetch the PR head with plain git, which needs no login for a repo you can
   already pull:

   ```bash
   git fetch origin pull/<n>/head        # GitLab: merge-requests/<n>/head
   git diff $(git merge-base origin/<default-branch> FETCH_HEAD) FETCH_HEAD
   git log --oneline origin/<default-branch>..FETCH_HEAD
   ```

   The PR title, description and CI status do not come with git. Ask the user to paste the
   description, and report both as "not available" rather than guessing them.
2. The current branch: `git diff $(git merge-base HEAD origin/main)...HEAD` — detect the
   real default branch rather than assuming `main`.
3. Uncommitted work: `git diff HEAD`.

Also read the PR description and commit messages; they are part of what you are grading.
Then read enough surrounding code to judge correctness — a diff alone hides whether a
changed function still satisfies its callers.

## 2. Score each category

Whole stars per category; overall is the weighted average to the nearest half star.

| Category | Weight |
|---|---|
| Correctness & Risk | 25% |
| Test Coverage of the Change | 20% |
| Scope & Cohesion | 20% |
| Code Quality of the Diff | 15% |
| Commit Hygiene & Description | 10% |
| Reviewability | 10% |

### Correctness & Risk (25%)
- **1** — Clear bug, broken contract, unhandled failure path, or a migration/data change with
  no rollback. Would cause an incident.
- **3** — Looks right on the happy path; edge cases, concurrency, or error handling are
  unexamined; one or two risky assumptions.
- **5** — Logic is verifiably right, edge and failure cases are handled, backward
  compatibility preserved or deliberately versioned, risky operations are reversible.

### Test Coverage of the Change (20%)
- **1** — New behavior, zero tests. Or tests changed only to stop failing.
- **3** — The main new path is tested; branches, error cases, and regressions are not.
- **5** — Every new branch exercised, a regression test for each bug fixed, tests fail
  meaningfully if the change is reverted.

### Scope & Cohesion (20%)
- **1** — Several unrelated concerns in one PR, or a feature buried inside a "refactor".
- **3** — One main purpose plus drive-by changes that should have been split out.
- **5** — One reviewable purpose; unrelated cleanups are absent or separated into their own
  commits clearly labelled as such.

### Code Quality of the Diff (15%)
- **1** — Debug statements, commented-out code, copy-paste, magic values, dead code left behind.
- **3** — Acceptable, but inconsistent with surrounding conventions in places.
- **5** — Reads like the rest of the codebase, removes as much as it adds where it can,
  leaves the touched area better.

### Commit Hygiene & Description (10%)
- **1** — "fix", "wip", "stuff". No description, or a description that does not match the diff.
- **3** — Reasonable messages; the description says *what* but not *why* or how to verify.
- **5** — Atomic commits with imperative subjects, a description covering motivation,
  approach, risk, and test plan, with linked issues.

### Reviewability (10%)
- **1** — Thousands of lines with generated output, lockfiles, and formatting churn mixed
  into logic changes.
- **3** — Large but navigable; noise and substance are mixed in places.
- **5** — Small enough to review in one sitting, or large but ordered so each commit stands
  alone; mechanical changes isolated from behavioral ones.

## 3. Calibrate

- **3 stars is the default** for a competent PR with normal gaps.
- Mixed evidence takes the lower band. Never round up to be encouraging.
- Judge the PR against the repo's own conventions, not your preferences.
- Do not penalize a PR for pre-existing problems it did not introduce — note them as
  "pre-existing, out of scope".

### Hard caps
| Condition | Cap |
|---|---|
| Introduces a secret, injection path, or missing authz check | **overall max 1.5**, mark **Do not merge** |
| Breaks the build, typecheck, or an existing test | **overall max 2** |
| Silently breaks a public API or data contract without a migration | **overall max 2.5** |
| Adds runtime behavior with no test at all | **overall max 3** |

## 4. Verify, don't assume

Where the tooling exists, run it on the branch and use the result as evidence: lint,
typecheck, the test suite, and the build. Report what actually ran and what it said. If
CI results are available via `gh pr checks`, read them rather than guessing. If they are
not available, say so in the report.

## 5. Report

Print the scorecard and save it to `.rate-my-code/pr-report.md`.

<!-- shared:history -->
Append one row to `.rate-my-code/history.md`, creating the file with this header if it is
missing:

```markdown
| Date | Type | Overall | Detail | Commit | Rubric |
|---|---|---|---|---|---|
```

Fill Rubric with `1`, the version of the scoring rubric. Only rows with the same rubric are
comparable. If the existing header has no Rubric column, add it to the header and separator
rows. Never rewrite past rows.
<!-- /shared:history -->

```markdown
# Rate My PR — #482 "Add refund flow"

**Overall: ★★★☆☆ 3.0 / 5** — Fair: mergeable after two fixes.
**Verdict: Request changes** (Approve / Approve with nits / Request changes / Do not merge)

| Category | Score | Weight |
|---|---|---|
| Correctness & Risk | ★★★☆☆ 3 | 25% |
| Test Coverage of the Change | ★★☆☆☆ 2 | 20% |
| Scope & Cohesion | ★★★★☆ 4 | 20% |
| Code Quality of the Diff | ★★★★☆ 4 | 15% |
| Commit Hygiene & Description | ★★★☆☆ 3 | 10% |
| Reviewability | ★★★★☆ 4 | 10% |

**Scope:** 14 files, +412 / -87, 6 commits, base `main` at `a1b2c3d`
**Checks:** lint pass · typecheck pass · tests 1 failing (`refund.spec.ts:44`)

## Blocking
Findings that must be fixed before merge.

## Non-blocking
Worth doing, not worth holding the merge.

## Nits
One line each. Explicitly optional.
```

Finding format — ID prefixes `PR` (correctness/scope), `TST`, `SEC`, `DOC`:

```markdown
#### [PR-01] Refund amount is not validated against the original charge
- **Severity:** High · **Effort:** S · **Impact:** Correctness +1 star · **Blocking**
- **Where:** `src/payments/refund.ts:52`
- **Why it matters:** A caller can refund more than was charged; the gateway rejects it
  asynchronously, so the local ledger is already wrong by then.
- **Fix:** Compare against `charge.amountRemaining` before calling the gateway and return
  a 422 on overflow. Cover with a test for the over-refund case.
```

Every finding cites a file and line, states whether it blocks, and is specific enough to
fix without further investigation.

## 6. Hand off

Offer to fix it:

> Two blocking items (PR-01, TST-01). Want me to fix them and re-rate? I can also leave
> this as a review comment on the PR instead.

Use the **`boost-my-score`** skill to apply the fixes by ID. If the user asks to post the
review, use `gh pr review` — but only when they explicitly ask, since that is visible to
their team. Without `gh`, give them the review as Markdown ready to paste.
