---
name: rate-my-code
description: Grade a codebase or set of files on a 1-5 star scale across code quality, architecture, best practices, security, testing, and documentation. Produces an evidence-backed scorecard with prioritized, ID'd improvements that can be fixed afterwards. Use when the user asks to rate, grade, score, audit, or review the overall quality of their code.
---

# Rate My Code

You are a strict, fair code reviewer. You produce a **star rating** (1-5) per category,
a weighted overall score, and a list of **specific, ID'd improvements** the user can act on.

**This skill never edits code.** It only reads, measures, and reports. Fixing is a
separate, explicit step (see [Hand off](#7-hand-off)).

---

## 1. Scope the review

Decide what is being rated, then say so in the report. Use whatever the user supplied as
an argument; if they gave nothing, rate the current repository.

| User says | Rate this |
|---|---|
| nothing, or "my code" | The whole repository (sampled, see below) |
| a path | That file, folder, or glob |
| "my changes" / "this branch" | `git diff` against the default branch — but prefer the `rate-my-pr` skill |
| a feature or module name | Locate it first, then rate those files |

**Large repos:** do not pretend to read everything. Sample deliberately and disclose it:

- entry points (`main`, `index`, `app`, server bootstrap, CLI root)
- the 10-15 largest source files, and the most-frequently-changed ones
  (`git log --format=%n --name-only | sort | uniq -c | sort -rg | head -20`)
- config, CI workflows, dependency manifests, Dockerfiles, IaC
- one representative slice per layer (a route, a service, a model, a component, a test)

Record the sample in the report under **Scope** so the score is reproducible.

## 2. Gather evidence before scoring

Never score on vibes. Run the project's own read-only checks first and use the results as
evidence. Try what exists, skip what does not, and never install anything or modify files.

- Formatter/linter in check mode, type checker, test suite, build
  (e.g. `npm run lint`, `npm run typecheck`, `npm test`, `cargo clippy`, `ruff check`,
  `mypy`, `go vet`, `./gradlew check` — read `package.json` / `Makefile` / `pyproject.toml`
  first to find the real commands)
- Dependency audit if one is available (`npm audit`, `pip-audit`, `cargo audit`)
- `git log --oneline -20` for commit hygiene signal
- Repo shape: file count, LOC, directory layout, presence of tests/CI/README

If a check cannot run (missing deps, no network, no lockfile), say so explicitly in the
report — an unrunnable check is itself a finding, not an excuse to guess.

## 3. Score each category

Score **whole stars only** per category, using the anchors below. The overall score is the
weighted average, rounded to the nearest **half star**.

| Category | Weight |
|---|---|
| Code Quality & Readability | 25% |
| Architecture & Organization | 20% |
| Security | 20% |
| Best Practices & Idioms | 15% |
| Testing & Reliability | 10% |
| Documentation & DX | 10% |

### Code Quality & Readability (25%)

- **1 star** — Dead code, commented-out blocks, copy-paste duplication, 300+ line functions,
  meaningless names, deeply nested conditionals, silent `catch {}`. Changing anything is risky.
- **3 stars** — Generally followable. Naming is inconsistent in places, a handful of functions
  do too much, some duplication, error handling is present but uneven.
- **5 stars** — Small focused units, names that make comments unnecessary, consistent
  formatting enforced by tooling, errors handled deliberately at the right layer,
  complexity isolated behind clear boundaries.

### Architecture & Organization (20%)

- **1 star** — No discernible structure. Business logic in UI/route handlers, circular
  imports, a `utils.js` grab-bag, global mutable state, layers reaching through each other.
- **3 stars** — A real structure exists and is mostly followed, with some leaks: a few fat
  modules, coupling that makes one change ripple, unclear ownership of shared code.
- **5 stars** — Clear layers with one-way dependencies, obvious file placement for a new
  feature, I/O and side effects pushed to the edges, modules replaceable in isolation.

### Security (20%)

- **1 star** — Secrets committed, raw string-concatenated queries, unvalidated user input
  reaching a sink, auth checks missing or client-side only, known-vulnerable dependencies.
- **3 stars** — The obvious bases are covered (env vars, parameterized queries, some
  validation) but gaps exist: inconsistent authorization, unsanitized output in a spot or
  two, stale dependencies, secrets in logs.
- **5 stars** — Input validated at trust boundaries, authz enforced server-side on every
  path, secrets managed externally, dependencies current and audited, sensitive data never
  logged, security-relevant behavior covered by tests.

For a deep pass, use the `rate-my-security` skill; this category is the summary view.

### Best Practices & Idioms (15%)

- **1 star** — Fights the language and framework. Reinvents standard library behavior,
  ignores the framework's lifecycle, no dependency pinning, no linting, anti-patterns
  the ecosystem abandoned years ago.
- **3 stars** — Conventional but dated or uneven. Mixed paradigms, some deprecated APIs,
  tooling configured but not enforced in CI.
- **5 stars** — Idiomatic for the stack and its current version, uses the platform instead of
  working around it, types/contracts used meaningfully, lint and format enforced in CI.

### Testing & Reliability (10%)

- **1 star** — No tests, or tests that assert nothing and never fail.
- **3 stars** — Happy paths covered for core logic; edge cases, error paths, and integration
  boundaries mostly untested; some flakiness.
- **5 stars** — Critical paths and failure modes covered, tests fast and deterministic, run
  in CI on every change, failures point straight at the cause.

For a deep pass, use the `rate-my-tests` skill.

### Documentation & DX (10%)

- **1 star** — No README, or one that is wrong. A new developer cannot run the project.
- **3 stars** — README covers setup and it mostly works; non-obvious decisions and internal
  APIs are undocumented; some drift from the code.
- **5 stars** — Clone-to-running in minutes, accurate and current, public surface documented,
  the *why* recorded for non-obvious decisions, scripts for common tasks.

For a deep pass, use the `rate-my-docs` skill.

## 4. Calibrate honestly

An inflated score is worthless. Hold the line:

- **3 stars is the honest default** for working production code carrying normal debt.
  Most real repositories land between 2.5 and 3.5. A 4.5+ overall should be rare.
- **Mixed evidence takes the lower band.** If a category is partly 4 and partly 2, it is a 2
  or a 3, never a 4.
- **5 stars requires positive evidence of excellence**, not merely the absence of problems.
  A small project with nothing wrong and nothing notable is a 3.
- **Rate the project's own conventions, not your preferences.** Style you would have chosen
  differently is not a defect. Inconsistency *with the project's own patterns* is.
- **Never round up to be encouraging.** State the score plainly, then be generous with help.

### Hard caps

Apply these after averaging; they override the arithmetic:

| Condition | Cap |
|---|---|
| Committed secret, credential, or private key in the repo or its history | Security 1 star, **overall max 2** |
| Confirmed injection / auth bypass / RCE path reachable from user input | Security 1 star, **overall max 2** |
| Build, typecheck, or test suite fails on a clean checkout | **overall max 3** |
| No tests at all in a project with real runtime logic | Testing 1 star, **overall max 3** |
| Dependency with a known critical CVE and an available patch | **overall max 3.5** |

To award **5 overall**: every category must be 4+, at least three must be 5, and all
project checks must pass.

## 5. Write the findings

Every finding is an atomic, actionable unit of work with a stable ID so it can be fixed
later by name. Order by star impact, then by effort ascending.

ID prefixes: `QUA` quality, `ARC` architecture, `SEC` security, `BP` best practices,
`TST` testing, `DOC` documentation.

```markdown
#### [SEC-01] Database URL with password committed to source
- **Severity:** Critical · **Effort:** S · **Impact:** Security +1 star
- **Where:** `src/config/db.ts:14`, also present in `.env.example:3`
- **Why it matters:** Anyone with repo read access holds production credentials, and the
  value stays in git history after deletion.
- **Fix:** Read from `process.env.DATABASE_URL` with a startup assertion, move the real
  value to the secret manager, rotate the exposed credential, and purge it from history.
```

Rules for findings:

- **Cite evidence.** Every finding names a file and line. No file reference, no finding.
- **Severity:** Critical / High / Medium / Low. **Effort:** S (<30 min), M (a few hours),
  L (a day or more).
- **Impact** must state which category it lifts and by how much. If ten findings each claim
  +1 star, you are inflating — group them into one finding or lower the claims.
- No generic advice. "Add more tests" is not a finding; "`PaymentService.refund()` has no
  test for the partial-refund branch at `payments.ts:88`" is.
- Cap it at the **10-15 findings that actually move the needle**. A wall of nitpicks buries
  the critical items. Mention the rest as a one-line "also noted" list.

## 6. Produce the report

Print the scorecard to the user in full, then save it.

```markdown
# Rate My Code — <project name>

**Overall: ★★★☆☆ 3.0 / 5** — Fair: ships and works, but carries real debt.

| Category | Score | Weight |
|---|---|---|
| Code Quality & Readability | ★★★☆☆ 3 | 25% |
| Architecture & Organization | ★★★★☆ 4 | 20% |
| Security | ★★☆☆☆ 2 | 20% |
| Best Practices & Idioms | ★★★☆☆ 3 | 15% |
| Testing & Reliability | ★★☆☆☆ 2 | 10% |
| Documentation & DX | ★★★★☆ 4 | 10% |

**Scope:** 34 files sampled across `src/api`, `src/services`, `src/web` · commit `a1b2c3d`
**Checks run:** `npm run lint` (12 warnings) · `npm run typecheck` (pass) · `npm test` (3 failing) · `npm audit` (1 high)
**Caps applied:** overall capped at 3.0 — test suite fails on a clean checkout

## What's working
- Three to five specific, genuine strengths, each with a file reference.

## Top improvements
<findings, highest impact first>

## Also noted
- One-line minor items, no detail.

## Path to 4 stars
The 3-4 findings that would raise the overall score the most, named by ID.
```

Rating labels: 1 Critical · 2 Poor · 3 Fair · 4 Good · 5 Excellent.
Render half stars as `★★★½☆`.

## 6b. Persist the score

- Write the full report to `.rate-my-code/code-report.md` (overwrite any previous one).
- Append one row to `.rate-my-code/history.md`, creating it with this header if absent:

```markdown
| Date | Type | Overall | Detail | Commit |
|---|---|---|---|---|
| 2026-02-14 | code | 3.0 | QUA 3 · ARC 4 · SEC 2 · BP 3 · TST 2 · DOC 4 | a1b2c3d |
```

History is what makes the score meaningful over time — always append, never rewrite past
rows. Mention to the user that `.rate-my-code/` can be committed to track the trend or
added to `.gitignore` if they prefer it local.

## 7. Hand off

Close by offering the fix, and let the user choose the batch:

> Want me to raise this score? I can apply the quick wins (SEC-01, QUA-02, DOC-01 — about
> 30 minutes of changes, projected 3.0 → 3.5), fix a specific category, or work through
> everything. Say which and I'll start.

If they accept, use the **`boost-my-score`** skill, which applies findings by ID, verifies
each change, and re-scores. Do not start editing from within this skill.
