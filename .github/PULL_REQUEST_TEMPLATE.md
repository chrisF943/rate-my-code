## The problem

<!-- What actually went wrong, in a real session? "My review agent flagged this" and
     "this could theoretically cause issues" are not problem statements. If you cannot
     name the session, error, or wrong score that motivated this, please don't open the PR. -->

## The change

<!-- One problem per PR. What did you change, and why that way? -->

## Tested on

<!-- Prompt changes that were never executed are guesses. Fill in at least one row. -->

| Harness | Version | What you ran | Result |
|---|---|---|---|
| e.g. Claude Code | 2.1.x | `/rate-my-code` on a Next.js app | scored 3.0, SEC-01 was correct |

## Checklist

- [ ] I read [AGENTS.md](../AGENTS.md)
- [ ] `./scripts/check.sh` passes
- [ ] `./install.sh --dry-run` still shows the right destinations
- [ ] If this changes scoring: I have included the repo and the before/after scores
- [ ] No new dependencies, build steps, or package manifests
