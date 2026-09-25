---
name: rate-my-docs
description: Grade a project's documentation on a 1-5 star scale across getting started, accuracy against the actual code, coverage of the public surface, structure, and example quality. Produces a scorecard with ID'd fixes. Use when the user asks to rate, grade, score, or review their README, docs, or documentation.
---

# Rate My Docs

Grade documentation by whether it **works for a reader**, not by how much of it exists.
The decisive test: could a competent developer who has never seen this project get it
running and make a change, using only the docs?

**This skill never edits code or docs.** Fixing is a separate step (see [Hand off](#6-hand-off)).

## 1. Inventory what exists

- `README.md`, `docs/`, `CONTRIBUTING.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `AGENTS.md` /
  `CLAUDE.md`, ADRs, wikis referenced from the repo
- In-code documentation: docstrings, JSDoc/TSDoc, type annotations, OpenAPI specs
- Generated API docs and whether the generator still runs

State what you reviewed in the report. If the project has no docs at all, that is a
1-star result — say it plainly and move to findings.

## 2. Verify accuracy against the code

This is the step most reviews skip, and it is where documentation actually fails.
**Check claims against reality** rather than reading prose for tone:

- Do the install and run commands exist? Cross-check every command against
  `package.json` scripts, `Makefile`, `pyproject.toml`, `justfile`.
- Do documented env vars match what the code reads? Grep for `process.env` / `os.environ`
  / `Env::var` and diff the two sets in both directions.
- Do documented endpoints, CLI flags, and function signatures match the source?
- Do code examples reference APIs that still exist with those parameters?
- Are version numbers, supported runtimes, and links current? Check for dead relative links.

Every mismatch you find is a finding with both locations cited.

## 3. Score each category

| Category | Weight |
|---|---|
| Getting Started | 25% |
| Accuracy & Freshness | 25% |
| Coverage of the Public Surface | 20% |
| Structure & Navigation | 15% |
| Examples & Clarity | 15% |

### Getting Started (25%)
- **1** — No setup instructions, or they fail immediately. Reader is blocked.
- **3** — Setup works but has undocumented prerequisites, missing env vars, or steps that
  require guessing. Maybe 30 minutes of friction.
- **5** — Clone to running in a few copy-pasteable commands. Prerequisites with versions,
  every required env var listed with an example value, verification step, and a
  troubleshooting note for the common failure.

### Accuracy & Freshness (25%)
- **1** — Instructions are wrong. Commands, flags, or APIs that no longer exist.
- **3** — Broadly correct with drift in details: a renamed script, a stale screenshot, an
  option removed two releases ago.
- **5** — Everything verifiable checks out against the current code. Docs updated in the
  same commits as the code they describe.

### Coverage of the Public Surface (20%)
- **1** — Consumers must read the source to use the thing at all.
- **3** — Main paths documented; edge behavior, errors, configuration, and less-common
  entry points are not.
- **5** — Every public API, CLI command, config option, and error condition documented,
  including what each one returns and when it fails.

### Structure & Navigation (15%)
- **1** — One undifferentiated wall of text, or scattered files with no index.
- **3** — Reasonable headings; finding a specific answer takes scanning.
- **5** — Predictable organization, a table of contents that matches the content, sections
  answering one question each, cross-links between related pages.

### Examples & Clarity (15%)
- **1** — No examples, or fragments that cannot run.
- **3** — Basic examples that work but stop short of realistic use; audience and prose level
  wander.
- **5** — Complete runnable examples with expected output, covering the common real task,
  not just `hello world`. Consistent voice, no unexplained jargon, *why* explained
  alongside *how*.

## 4. Calibrate

- **3 stars is the default** for a README that covers setup and basic usage — that is
  normal, not good.
- Volume is not quality. Extensive docs that are wrong score **worse** than a short
  accurate README, because wrong docs cost the reader more than missing ones.
- Judge against the project's audience: an internal service needs less than a public SDK.
  Note the audience you assumed.
- Mixed evidence takes the lower band. Never round up.

### Hard caps
| Condition | Cap |
|---|---|
| Documented setup steps do not work | Getting Started 1 star, **overall max 2** |
| No README at all | **overall max 1.5** |
| Examples reference APIs that no longer exist | Accuracy 1 star, **overall max 2.5** |
| Public library with no API reference | **overall max 3** |

## 5. Report

Print the scorecard, save it to `.rate-my-code/docs-report.md`, and append a row to
`.rate-my-code/history.md` (create with the header
`| Date | Type | Overall | Detail | Commit |` if missing).

```markdown
# Rate My Docs — <project name>

**Overall: ★★½☆☆ 2.5 / 5** — Poor to fair: gets you running, then leaves you alone.

| Category | Score | Weight |
|---|---|---|
| Getting Started | ★★★☆☆ 3 | 25% |
| Accuracy & Freshness | ★★☆☆☆ 2 | 25% |
| Coverage of the Public Surface | ★★☆☆☆ 2 | 20% |
| Structure & Navigation | ★★★★☆ 4 | 15% |
| Examples & Clarity | ★★★☆☆ 3 | 15% |

**Reviewed:** `README.md`, `docs/` (6 files), TSDoc in `src/client/`
**Assumed audience:** external consumers of the published npm package
**Accuracy check:** 4 of 11 documented commands mismatch `package.json`

## What's working
## Top improvements
## Also noted
## Path to 4 stars
```

Finding format, ID prefix `DOC`:

```markdown
#### [DOC-03] Documented start command does not exist
- **Severity:** High · **Effort:** S · **Impact:** Accuracy +1 star
- **Where:** `README.md:41` says `npm run serve`; `package.json:12` defines `dev` and `start`
- **Why it matters:** The first command a new user runs fails, which is where most readers
  give up on a project.
- **Fix:** Replace with `npm run dev`, and add a verification line ("open http://localhost:3000,
  you should see the login page").
```

Cite both the doc location and the code location it contradicts.

## 6. Hand off

> Want me to fix these? The accuracy items (DOC-01 through DOC-04) are quick and would take
> this from 2.5 to about 3.5. Writing the missing API reference is the bigger job.

Use the **`boost-my-score`** skill to apply fixes by ID. When writing docs, match the
project's existing voice and format instead of imposing a new style, and verify every
command you write by running it.
