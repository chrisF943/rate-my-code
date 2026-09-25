---
name: rate-my-tests
description: Grade a test suite on a 1-5 star scale across critical-path coverage, assertion quality, determinism, speed, edge-case handling, and maintainability. Produces a scorecard with ID'd fixes. Use when the user asks to rate, grade, score, or review their tests, test suite, or test coverage.
---

# Rate My Tests

Grade a test suite by the only thing that matters: **would it catch a real regression
before it reaches production?** Coverage percentage is a weak proxy — a suite at 90%
coverage that asserts nothing scores 1 star here.

**This skill never edits code.** Fixing is a separate step (see [Hand off](#6-hand-off)).

## 1. Map the suite

- Locate test files and identify the runner and config (`jest.config`, `vitest.config`,
  `pytest.ini`, `go test`, `cargo test`, `rspec`).
- Count tests by level: unit / integration / end-to-end. Note the shape — a suite that is
  99% unit tests with no integration coverage has a specific blind spot, and so does the
  inverse.
- Identify the critical paths of the application (auth, payments, data writes, permissions,
  anything irreversible) and check which have tests at all.

## 2. Run the suite and measure

Evidence beats reading. Run the tests and record the real result:

- Run the suite. Note pass/fail, wall-clock time, and any skipped or `.only` tests.
- Run it **twice** if it is fast enough; differing results mean flakiness, which is a
  major finding.
- Generate coverage if the project already supports it (`--coverage`, `pytest --cov`).
  Report it as context, never as the score itself.
- Check CI config: do tests actually gate merges, or can a red suite ship?

Also apply a **mutation-thinking spot check** on two or three critical tests: if you
inverted the condition or deleted a line in the code under test, would any assertion fail?
If not, that test is decorative — cite it.

## 3. Score each category

| Category | Weight |
|---|---|
| Critical-Path Coverage | 25% |
| Assertion Quality | 20% |
| Determinism & Isolation | 20% |
| Edge & Failure Cases | 15% |
| Speed & CI Integration | 10% |
| Maintainability | 10% |

### Critical-Path Coverage (25%)
- **1** — The paths that would cause real damage if broken have no tests.
- **3** — Core happy paths covered; important branches, integrations, and irreversible
  operations are not.
- **5** — Every critical path covered at the right level, including the interactions between
  components, not just units in isolation.

### Assertion Quality (20%)
- **1** — Tests that call code and assert nothing, assert only `toBeTruthy()`, or snapshot
  everything and were regenerated the last time they failed.
- **3** — Real assertions on the main result, but loose: checks that something happened
  without checking it was correct.
- **5** — Asserts the specific expected value and the relevant side effects, fails with a
  message that identifies the cause, and would fail if the implementation regressed.

### Determinism & Isolation (20%)
- **1** — Flaky. Depends on wall-clock time, real network, ordering, or shared mutable state
  between tests. `sleep` used as synchronization.
- **3** — Mostly reliable; some order dependence, real I/O, or occasional flakes tolerated
  by reruns.
- **5** — Same result every run in any order, time and randomness injected, external services
  faked at a deliberate boundary, each test sets up and tears down its own state.

### Edge & Failure Cases (15%)
- **1** — Happy path only.
- **3** — A few obvious edge cases; error paths, empty/null inputs, and boundaries largely
  untested.
- **5** — Boundaries, empty and malformed inputs, permission denials, timeouts, and partial
  failures are all tested, and error messages themselves are asserted.

### Speed & CI Integration (10%)
- **1** — Too slow to run locally, or not run in CI at all.
- **3** — Runs in CI; slow enough that developers skip it locally.
- **5** — Fast feedback locally, full suite gates every merge, failures are reported clearly.

### Maintainability (10%)
- **1** — Copy-pasted setup everywhere, opaque fixtures, names like `test1`, mocks that
  restate the implementation line by line.
- **3** — Reasonable helpers with some duplication and over-mocking.
- **5** — Intent-revealing names, shared setup through clear factories, tests that read as a
  specification and survive refactors of the implementation.

## 4. Calibrate

- **3 stars is the default** for a suite that covers the happy paths and runs in CI.
- **High coverage does not raise the score.** Assertion quality and critical-path coverage do.
  If coverage is high but assertions are weak, say so explicitly — it is the most common
  and most dangerous finding in this review.
- Tests coupled to implementation details are a **negative**, not a positive: they fail on
  refactors and pass on regressions.
- Mixed evidence takes the lower band. Never round up.

### Hard caps
| Condition | Cap |
|---|---|
| Suite fails, or contains committed `.only` / skipped critical tests | **overall max 2** |
| Flaky: two runs disagree | Determinism 1 star, **overall max 2.5** |
| Tests exist but assert nothing meaningful | Assertion Quality 1 star, **overall max 2** |
| Tests do not run in CI | **overall max 3** |
| No tests for an irreversible operation (payments, deletes, migrations) | **overall max 3** |

## 5. Report

Print the scorecard, save it to `.rate-my-code/tests-report.md`, and append a row to
`.rate-my-code/history.md` (create with the header
`| Date | Type | Overall | Detail | Commit |` if missing).

```markdown
# Rate My Tests — <project name>

**Overall: ★★★☆☆ 3.0 / 5** — Fair: catches obvious breakage, misses the expensive kind.

| Category | Score | Weight |
|---|---|---|
| Critical-Path Coverage | ★★☆☆☆ 2 | 25% |
| Assertion Quality | ★★★☆☆ 3 | 20% |
| Determinism & Isolation | ★★★★☆ 4 | 20% |
| Edge & Failure Cases | ★★☆☆☆ 2 | 15% |
| Speed & CI Integration | ★★★★★ 5 | 10% |
| Maintainability | ★★★★☆ 4 | 10% |

**Suite:** 214 tests (198 unit, 16 integration, 0 e2e) · runner Vitest · 12.4s
**Result:** 214 passing, 2 skipped · stable across 2 runs · line coverage 78%
**Blind spot:** no test touches the refund or account-deletion paths

## What's working
## Top improvements
## Also noted
## Path to 4 stars
```

Finding format, ID prefix `TST`:

```markdown
#### [TST-02] Refund flow has no test at any level
- **Severity:** Critical · **Effort:** M · **Impact:** Critical-Path Coverage +2 stars
- **Where:** `src/payments/refund.ts` (no matching spec); nearest is `payments.spec.ts:12`
  which covers charges only
- **Why it matters:** Refunds move real money and are not reversible. A regression here is
  discovered by customers, not by the suite.
- **Fix:** Add `refund.spec.ts` covering full refund, partial refund, over-refund rejection,
  double-refund idempotency, and gateway timeout, with the gateway faked at the client
  boundary.
```

## 6. Hand off

> Want me to close the gaps? TST-02 and TST-04 cover the two untested critical paths and
> would take this from 3.0 to roughly 4.0. I'd write them as failing tests first, then
> confirm they pass against current behavior.

Use the **`boost-my-score`** skill to apply fixes by ID. When writing tests, first confirm
each new test **fails** if the behavior it covers is broken — a test that passes no matter
what is worse than no test, and it would score 1 star on the next run.
