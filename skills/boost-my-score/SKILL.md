---
name: boost-my-score
description: Apply the improvements from a previous rate-my-code, rate-my-pr, rate-my-docs, rate-my-tests, or rate-my-security report, then re-rate to show the score change. Fixes findings by ID, verifies each one, and never makes unrelated changes. Use when the user asks to fix the findings, raise their score, improve their rating, or act on the review.
---

# Boost My Score

Turn a scorecard into applied changes. You fix findings **by ID**, verify each one, and
report the before-and-after score.

Your job is to raise the real quality of the code. Never optimize for the number: changing
a report, weakening a test, or suppressing a linter to make a score go up is a failure, not
a fix.

## 1. Load the findings

Read the relevant report from `.rate-my-code/`:
`code-report.md`, `pr-report.md`, `docs-report.md`, `tests-report.md`, `security-report.md`.

If none exists, or the report predates the current HEAD by meaningful changes, run the
matching `rate-my-*` skill first — fixing findings against stale evidence wastes the
user's time.

## 2. Agree on the batch

Never start a large batch unsupervised. Confirm scope first, offering these options:

| Batch | Meaning |
|---|---|
| **Quick wins** | Effort S findings with High or Critical severity — best score per minute |
| **By ID** | Exactly the IDs the user names, e.g. "SEC-01 and TST-02" |
| **By category** | Everything lifting one category, e.g. all `SEC` findings |
| **Everything** | All findings, in impact order |

For each batch, state upfront: the IDs, what will change, the projected score movement,
and anything that alters behavior or public API.

**Always fix Critical security findings first**, regardless of the chosen batch. Say so if
the user's selection skips one.

## 3. Apply one finding at a time

For each finding, in order:

1. **Re-read the code.** The report is a claim; confirm it still holds before changing
   anything. If the finding is wrong or already fixed, say so and skip it — do not
   manufacture work.
2. **Make the minimal change** that resolves the finding. Match the file's existing style
   and the project's conventions.
3. **Verify it.** Run the project's own checks for the touched area: tests, typecheck,
   lint, build. For a security fix, add or run a test that proves the attack path is closed.
   For a docs fix, run the command you documented.
4. **Report the result** in one line: `[SEC-01] fixed — orders scoped to session user,
   regression test added, 214 tests pass.`

If a verification fails, fix the cause before moving on. Never leave the tree broken while
starting the next finding.

### Rules of engagement

- **No drive-by changes.** Touch only what the finding requires. A tempting nearby cleanup
  is a new finding, not part of this one.
- **No suppression as a fix.** No `eslint-disable`, `# type: ignore`, `--no-verify`, skipped
  tests, or widened types to make a check pass. If suppression is genuinely correct, explain
  why in a comment and flag it to the user.
- **No weakening tests.** Never change an assertion to match broken behavior. If a test
  fails after your change, the change is probably wrong.
- **Stop and ask** before: changing a public API or data contract, altering behavior beyond
  the finding's description, adding a dependency, running a migration, touching auth logic
  in a way that could lock users out, or rotating a live credential (tell the user to do
  that themselves).
- **Keep changes reviewable.** Finding-sized commits with the ID in the message
  (`fix(security): scope order lookup to session user [SEC-01]`) — but only commit if the
  user asked you to; otherwise leave the work staged for their review.
- **Some findings are not yours to fix.** Architectural rework, anything needing a product
  decision, and credential rotation get flagged with a recommendation instead of a patch.

## 4. Re-rate and show the delta

Once the batch is done, re-run the matching `rate-my-*` skill over the affected scope with
the same rubric and the same strictness. **Do not re-score from memory** and do not assume
a fix landed the star it promised — re-read the code and re-run the checks.

Then report the movement:

```markdown
# Boost My Score — results

**Overall: ★★★☆☆ 3.0 → ★★★★☆ 4.0** (+1.0)

| Category | Before | After | |
|---|---|---|---|
| Code Quality & Readability | ★★★☆☆ 3 | ★★★★☆ 4 | +1 |
| Security | ★★☆☆☆ 2 | ★★★★☆ 4 | +2 |
| Testing & Reliability | ★★☆☆☆ 2 | ★★★☆☆ 3 | +1 |
| Architecture & Organization | ★★★★☆ 4 | ★★★★☆ 4 | — |

**Applied:** SEC-01, SEC-03, QUA-02, TST-02 (4 of 11)
**Skipped:** SEC-02 — requires rotating the live key, which only you can do
**Deferred:** ARC-01 — 2-day refactor, needs your call on the module boundary
**Verification:** 218 tests pass (4 new) · typecheck pass · lint clean · `npm audit` 0 high
**Files changed:** 9
```

Be honest when a fix did not move a star. Partial progress within a band is a real outcome:
say "Security 2 → 3; reaching 4 needs the remaining authz audit (SEC-04)."

## 5. Record it

- Update the source report: mark applied findings as `✅ Fixed`, keep skipped and deferred
  ones with a one-line reason so the next run does not re-litigate them.
- Append a row to `.rate-my-code/history.md` using the same table format as the rating
  skills, so the trend line shows the improvement.
- Close with the single highest-value next step, named by ID.
