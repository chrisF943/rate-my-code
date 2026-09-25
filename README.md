<div align="center">

# Rate My Code

**A star-rating review system for your codebase.**

Ask your AI coding agent to rate your code and it hands back a 1–5 star scorecard per
category, the specific findings behind each score, and an offer to fix them.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Skills: 6](https://img.shields.io/badge/skills-6-F5A623.svg)](#the-skills)
[![Works with: 10 agents](https://img.shields.io/badge/works%20with-Claude%20Code%20%C2%B7%20Codex%20%C2%B7%20Gemini%20%C2%B7%20Cursor%20%C2%B7%20Warp%20%C2%B7%20Cline%20%C2%B7%20%2B4-555.svg)](#install)

</div>

```
Overall: ★★★☆☆ 3.0 / 5 — Fair: ships and works, but carries real debt.

Code Quality & Readability   ★★★☆☆ 3   25%
Architecture & Organization  ★★★★☆ 4   20%
Security                     ★★☆☆☆ 2   20%
Best Practices & Idioms      ★★★☆☆ 3   15%
Testing & Reliability        ★★☆☆☆ 2   10%
Documentation & DX           ★★★★☆ 4   10%

Caps applied: overall capped at 3.0 — test suite fails on a clean checkout
```

Every finding gets an ID, so fixing is a conversation:

> **[SEC-01] Database URL with password committed to source**
> Severity: Critical · Effort: S · Impact: Security +1 star
> Where: `src/config/db.ts:14`

> *"Fix SEC-01 and the quick wins."* → `boost-my-score` applies them, verifies each one,
> re-runs the review, and shows you `3.0 → 3.5`.

---

## The skills

| Skill | Rates | Categories |
|---|---|---|
| **`rate-my-code`** | A codebase, folder, or file | quality · architecture · security · best practices · testing · docs |
| **`rate-my-pr`** | A PR, branch, or diff | correctness · test coverage of the change · scope · diff quality · commit hygiene · reviewability |
| **`rate-my-docs`** | README and docs | getting started · accuracy vs. the code · coverage · structure · examples |
| **`rate-my-tests`** | A test suite | critical-path coverage · assertion quality · determinism · edge cases · speed · maintainability |
| **`rate-my-security`** | Security posture | secrets · injection · authn/authz · dependencies · data protection · hardening |
| **`boost-my-score`** | *(the fixer)* | Applies findings by ID, verifies each change, re-rates and shows the delta |

The five `rate-my-*` skills are **read-only**. They measure and report; they never touch
your code. Only `boost-my-score` edits anything, and only after you pick a batch.

## Install

One command. It finds the agents you have and wires up each one:

```bash
git clone https://github.com/chrisF943/rate-my-code
cd rate-my-code
./install.sh
```

```
Looking for installed agents…

  found    Claude Code          (claude CLI)
  missing  OpenAI Codex CLI
  found    Gemini CLI           (gemini CLI)
  found    Google Antigravity   (Antigravity.app)
  missing  Warp
  missing  OpenCode
  missing  Cursor
  missing  Qwen Code
  missing  Cline
  missing  Factory Droid

Install rate-my-code into 3 tool(s)? [Y/n]
```

**Claude Code gets the real plugin**, not loose files — the installer registers
`chrisF943/rate-my-code` as a marketplace and installs from it, so the skills arrive as
`/rate-my-code`, `/rate-my-pr` and so on, and `/plugin marketplace update rate-my-code`
pulls new versions. (Working on the skills themselves? `--local` registers your checkout
instead, so unpushed edits load.) Every other tool reads the
same `SKILL.md` format, so there the installer copies the six skills into the directory that
tool scans.

| Tool | Where it lands |
|---|---|
| Claude Code | plugin via the `claude` CLI, or `~/.claude/skills` without it |
| OpenAI Codex CLI | `~/.agents/skills` |
| Gemini CLI | `~/.agents/skills` |
| Google Antigravity | `~/.agents/skills` |
| Warp | `~/.agents/skills` |
| OpenCode | `~/.config/opencode/skills` |
| Cursor | `~/.cursor/skills` |
| Qwen Code | `~/.qwen/skills` |
| Cline | `~/.cline/skills` |
| Factory Droid | `~/.factory/skills` |

Four of those share one directory: `.agents/skills` is the cross-tool convention, and the
installer writes it once rather than four times.

Run `./install.sh --dry-run` first if you want to see the plan without writing anything.

| Flag | Effect |
|---|---|
| `--tool NAME` | Skip detection and target specific tools: `--tool codex,cursor` (or `all`) |
| `--project` | Install into the current repo instead of your home directory |
| `--dir PATH` | Install into an explicit directory, for a tool not listed above |
| `--skills-only` | Copy skills into `~/.claude/skills` instead of installing the plugin |
| `--local` | Register the Claude marketplace from your checkout rather than GitHub |
| `--dry-run` | Show what would happen, change nothing |
| `--uninstall` | Remove the plugin and the six skills everywhere they were installed |
| `-y`, `--yes` | Skip the confirmation prompt |

### Installing by hand

Nothing here is compiled and nothing is fetched, so every install is either a manifest
your tool already reads or a directory copy. Do it yourself if you prefer:

**Claude Code** — from inside a session:

```
/plugin marketplace add chrisF943/rate-my-code
/plugin install rate-my-code
```

**Anything else** — copy the six skill directories into the folder that tool scans:

```bash
cp -R skills/* ~/.agents/skills/        # Codex, Gemini CLI, Antigravity, Warp
cp -R skills/* ~/.cursor/skills/        # Cursor
cp -R skills/* ~/.config/opencode/skills/
cp -R skills/* ~/.qwen/skills/          # Qwen Code
cp -R skills/* ~/.cline/skills/         # Cline
```

Using an agent that isn't listed at all? If it reads `.agents/skills/` — the emerging
cross-tool convention — `./install.sh --tool agents` covers it. Otherwise point `--dir` at
its skills folder, or copy `skills/` there yourself. There is nothing Claude-specific
inside a `SKILL.md`: no tool names, no `~/.claude` paths, no vendor assumptions.

### What's in the repo

The repo root *is* the plugin, so a tool can load it straight from a clone.

```
skills/                       the six SKILL.md files — the whole product
install.sh                    detect installed agents and wire them up
.claude-plugin/               Claude Code plugin + marketplace manifests
.agents/plugins/              the cross-harness .agents standard
.codex-plugin/                OpenAI Codex manifest
.cursor-plugin/               Cursor manifest
scripts/check.sh              frontmatter, JSON, version sync
```

Adding support for another harness is usually one entry in `install.sh` plus a manifest —
see [AGENTS.md](AGENTS.md).

## Use it

Plain language works; the descriptions are written so agents pick the right skill:

```
rate my code
rate my code in src/payments
rate this PR before I merge it
rate my tests
rate my security
how bad is my documentation
fix SEC-01 and TST-02, then re-rate
raise my score — quick wins only
```

## How the scoring works

**3 stars is the honest default** for working production code carrying normal debt. Most
real repositories land between 2.5 and 3.5, and the skills are explicitly told not to round
up to be encouraging. A score you can't trust is worthless.

- **Evidence before scoring.** Each skill runs your project's own checks first — lint,
  typecheck, tests, build, dependency audit — and reports what actually ran. A check that
  can't run is itself a finding, not an excuse to guess.
- **Every finding cites a file and line.** No reference, no finding. "Add more tests" isn't
  a finding; "`refund()` has no test for the partial-refund branch at `payments.ts:88`" is.
- **Mixed evidence takes the lower band**, always.
- **Hard caps override the arithmetic.** A committed secret caps the overall at 2 stars no
  matter how elegant the rest is. A failing test suite caps it at 3.
- **5 stars needs positive evidence of excellence**, not just the absence of problems.

Scores are judged against your project's own conventions, not the reviewer's preferences.

## Scorecards are saved

Each run writes its report to `.rate-my-code/` and appends one row to
`.rate-my-code/history.md`:

```markdown
| Date | Type | Overall | Detail | Commit |
|---|---|---|---|---|
| 2026-02-14 | code | 3.0 | QUA 3 · ARC 4 · SEC 2 · BP 3 · TST 2 · DOC 4 | a1b2c3d |
| 2026-02-14 | code | 3.5 | QUA 4 · ARC 4 · SEC 4 · BP 3 · TST 3 · DOC 4 | 9e8d7c6 |
```

Commit that folder to track the trend over time, or add it to `.gitignore` to keep it local.
This repo ignores it by default.

## A note on the security rating

`rate-my-security` is a static review by an AI reading source code. It reliably finds common,
real classes of vulnerability, and it says so in every report: it is **not** a penetration
test, it does not execute attacks, and it cannot prove a vulnerability is absent. For
anything handling money, health data, or credentials at scale, it supplements a professional
audit rather than replacing one.

## Contributing

The most valuable thing you can report is **a score that was wrong** — open a rating
dispute with the repo and the scorecard. Calibration is the hard part, and it can't be
tuned alone.

Read [AGENTS.md](AGENTS.md) for the scoring contract that every rater has to keep, and
[CONTRIBUTING.md](CONTRIBUTING.md) for the mechanics. Run `./scripts/check.sh` before
opening a PR.

## License

MIT — see [LICENSE](LICENSE).
