# Contributing

Thanks for wanting to help. The project is Markdown and one shell script, so getting
set up is `git clone` and nothing else.

Please read [AGENTS.md](AGENTS.md) first — it holds the real rules, including the scoring
contract that every rater has to keep. This file is just the mechanics.

## Try your change

```bash
git clone https://github.com/chrisF943/rate-my-code
cd rate-my-code
./install.sh --project      # installs into this repo only, nothing global
```

Then open your agent in a real project and use the skill. Reading a diff of a prompt tells
you very little; running it against a codebase you know well tells you everything.

## Before opening a PR

```bash
./scripts/check.sh
./install.sh --dry-run
```

Then say in the PR **which harness you tested on** — Claude Code, Codex, Cursor, OpenCode,
Droid — and what you actually ran. A prompt change that was never executed is a guess.

## What gets merged

- A rater that scored something wrongly, with the repo and the score to prove it.
- Harness support that you have run yourself.
- Findings that were vague, unciteable, or not actionable.

## What gets closed

- Score inflation with no evidence behind it.
- New `rate-my-*` skills whose categories overlap the existing six.
- Rewrites of the voice or structure of a skill without a problem statement.
- Dependencies, build steps, or package manifests. See AGENTS.md for why.

## Reporting a wrong score

Open a **Rating dispute** issue. Include the repository (or a reduced example), the score
you got, the score you expected, and which category you think is wrong. Calibration bugs
are the most valuable reports this project can get, and the hardest to find alone.
