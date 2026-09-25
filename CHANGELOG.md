# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — unreleased

First release.

### Added

- `rate-my-code` — six-category scorecard for a codebase, folder or file: code quality,
  architecture, security, best practices, testing, documentation.
- `rate-my-pr`, `rate-my-docs`, `rate-my-tests`, `rate-my-security` — focused raters with
  their own category sets.
- `boost-my-score` — applies findings by ID, verifies each change, re-rates and reports
  the delta.
- Scoring contract shared by every rater: 3 stars is the default, evidence is gathered
  before scoring, every finding cites a file and line, mixed evidence takes the lower
  band, and hard caps override the arithmetic.
- Reports persist to `.rate-my-code/` with a row appended to `history.md`, so the score
  becomes a trend line.
- `install.sh` — detects the agents you have installed and wires each one up. Claude Code
  gets the native plugin via its CLI; other harnesses get the skills copied into the
  directory they scan. Supports `--tool`, `--dir`, `--project`, `--skills-only`,
  `--dry-run`, `--uninstall` and `-y`.
- Manifests for Claude Code (`.claude-plugin/`), the `.agents` cross-harness standard
  (`.agents/plugins/`), Codex (`.codex-plugin/`) and Cursor (`.cursor-plugin/`).

[Unreleased]: https://github.com/chrisF943/rate-my-code/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/chrisF943/rate-my-code/releases/tag/v0.1.0
