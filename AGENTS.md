# Rate My Code — contributor guidelines

This file is the single source of truth for contributors, human and agent.
`CLAUDE.md` and `GEMINI.md` point here.

## What this project is

Six skills that grade code on a 1–5 star scale and then fix what they found. Five raters
are read-only; `boost-my-score` is the only one that edits. There is no runtime, no build
step and no dependencies — the whole product is Markdown that an agent reads.

That constraint is deliberate. **Do not add a package manifest, a compiled component, or a
dependency.** If a change needs one, it belongs in a different project.

## If you are an AI agent

Read this whole file before editing. Then:

1. **Do not "improve" the scoring to be nicer.** Score inflation is the one failure mode
   that makes this project worthless. A PR that softens an anchor, removes a cap, or
   rounds up needs evidence that real projects are being scored wrongly — not a feeling
   that 3 stars seems harsh.
2. **Do not add speculative skills.** `rate-my-<anything>` is easy to generate and mostly
   noise. A new rater needs a category set that does not overlap the existing six.
3. **One problem per PR.** Describe the session or report that motivated it.

## The scoring contract

Every rater must keep all of these. They are what makes a score mean something:

- **3 stars is the default** for working production code carrying normal debt. Most real
  repositories land between 2.5 and 3.5.
- **Evidence before scoring.** Run the project's own lint, typecheck, tests, build and
  dependency audit first, and report what actually ran. A check that cannot run is itself
  a finding, not permission to guess.
- **Every finding cites a file and line.** No reference, no finding.
- **Mixed evidence takes the lower band.**
- **Hard caps override the arithmetic** (a committed secret caps overall at 2; a failing
  suite caps it at 3).
- **5 stars needs positive evidence of excellence**, not merely the absence of problems.
- **Judge against the project's own conventions**, not the reviewer's preferences.

## Adding or editing a skill

Each skill is one directory under `skills/` containing a single `SKILL.md`.

Frontmatter rules, all enforced by `./scripts/check.sh`:

- `name` must equal the directory name, and be lowercase kebab-case.
- `description` must be under 1024 characters, and must say *when to use it* — that
  sentence is the only thing an agent sees when deciding whether to load the skill.
- Nothing else in the frontmatter. No tool lists, no model pins.

Keep the body harness-neutral: no `Task`/`TodoWrite`/`Bash` tool names, no
`~/.claude` paths, no "Claude" in instructions the agent will follow. The same file has to
work in Codex, Gemini CLI, Cursor, Warp, OpenCode, Qwen Code, Cline and Droid.

## Adding support for a new harness

1. Add its detection and destination to `install.sh` (`detect_reason`, `dest_for`,
   `TOOLS`, and the tool table in `usage`).
2. If it reads a native manifest, add `.<tool>-plugin/plugin.json` at the repo root
   mirroring `.codex-plugin/plugin.json`. If it reads `.agents/`, nothing is needed.
3. Add a row to the destinations table in `README.md`.
4. Test it for real and say so in the PR: which harness, which version, what you ran.

## Before you open a PR

Editing a skill and testing it in Claude Code? Install with `./install.sh --tool claude
--local`. The default registers the marketplace from `chrisF943/rate-my-code`, which means
a plain `./install.sh` loads the *pushed* skills and your local edits do nothing.

```bash
./scripts/check.sh          # frontmatter, JSON, version sync, shellcheck if present
./install.sh --dry-run      # detection and destinations, writes nothing
claude plugin validate .    # if you have the Claude Code CLI
```

Bumping the version touches four manifests. Use `./scripts/bump-version.sh <version>` so
they cannot drift.
