---
name: Harness support
about: Ask for, or report on, support for another agentic coding tool
title: '[HARNESS] '
labels: harness-support
---

## Which tool

<!-- Name, link, and version. -->

## How it loads skills

<!-- This is the part that decides whether support is a one-line change or a real port. -->

- Directory it scans for skills, globally and per-project:
- Does it read `SKILL.md` with `name` / `description` frontmatter?
- Does it read the `.agents/` convention? If so, support may already work today —
  try `./install.sh --tool agents`.
- Does it have a native plugin manifest? Link to the schema if you have it.
- Is there a CLI that can install a plugin, the way `claude plugin install` does?

## Have you tried it already

<!-- `./install.sh --dir <its skills folder>` copies the six skills anywhere.
     If that worked, say so — support may be one entry in install.sh. -->
