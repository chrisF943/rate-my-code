---
name: rate-my-security
description: Grade a codebase's security posture on a 1-5 star scale across secrets handling, input validation and injection, authentication and authorization, dependencies, data protection, and deployment hardening. Produces a scorecard with severity-ranked, ID'd fixes. Use when the user asks to rate, grade, score, audit, or review the security of their code.
---

# Rate My Security

A focused security review with a star rating. Findings are ranked by exploitability, not
by how alarming they sound.

**This skill never edits code.** Fixing is a separate step (see [Hand off](#7-hand-off)).

**State this limitation in every report:** this is a static review by an AI reading source
code. It finds common, real classes of vulnerability. It is not a penetration test, it does
not execute attacks, and it cannot prove the absence of a vulnerability. For systems
handling money, health data, or credentials at scale, this supplements a professional
audit — it does not replace one.

## 1. Map the attack surface first

Do not start by grepping for bad functions. Start by understanding where untrusted input
enters and what it can reach:

- **Entry points:** HTTP routes, GraphQL resolvers, webhooks, CLI args, queue consumers,
  file uploads, websocket handlers, deserialization points
- **Trust boundaries:** where user input crosses into a database, shell, filesystem, HTTP
  client, template renderer, or `eval`-equivalent
- **Sensitive assets:** credentials, tokens, PII, payment data, and the code paths that read
  or write them
- **Auth model:** how identity is established and where permissions are checked

Then trace the high-value paths from entry point to sink. A finding is real when you can
name the path.

## 2. Check each category for concrete issues

Run whatever the project supports (`npm audit`, `pip-audit`, `cargo audit`,
`gitleaks detect`, `bandit`, `semgrep`) and use real output as evidence. Never install new
tooling; note what was unavailable.

**Secrets:** hardcoded keys, tokens, or passwords in source, config, or test fixtures;
credentials in git history (`git log -p -S'api_key' -S'password' --all | head -100`);
`.env` files committed; secrets printed to logs or error responses; overly broad
`.gitignore` gaps.

**Input validation & injection:** string-built SQL, NoSQL query objects taken from request
bodies, shell execution with interpolated input, path traversal in file reads,
unsanitized HTML output (XSS), template injection, SSRF in server-side fetches, unbounded
deserialization, missing size/type limits on uploads.

**AuthN/AuthZ:** endpoints with no auth check, authorization performed only in the UI,
missing object-level checks (can user A read user B's record by changing an ID?), JWTs
without signature or expiry verification, weak session handling, password storage without
a modern KDF, no rate limiting on auth endpoints.

**Dependencies:** known CVEs with available patches, unpinned or unlocked versions,
abandoned packages, install scripts from untrusted sources, dependencies pulled from
mutable refs.

**Data protection:** PII or tokens in logs and error traces, missing encryption in transit
or at rest where warranted, home-rolled cryptography, weak or misused algorithms (ECB,
MD5/SHA1 for passwords, static IVs), tokens with no expiry or rotation.

**Config & deployment:** debug mode or verbose errors reachable in production, permissive
CORS (`*` with credentials), missing security headers, containers running as root, secrets
baked into images, cloud resources open to the world, CI credentials with excessive scope.

## 3. Score each category

| Category | Weight |
|---|---|
| Secrets & Credential Handling | 20% |
| Input Validation & Injection | 20% |
| Authentication & Authorization | 20% |
| Dependencies & Supply Chain | 15% |
| Data Protection | 15% |
| Config & Deployment Hardening | 10% |

Generic anchors, applied per category:

- **1 star** — An exploitable weakness of this class exists and is reachable from untrusted
  input. Assume it will be found.
- **2 stars** — Serious gaps with partial mitigation, or an issue exploitable only with
  elevated access or unusual conditions.
- **3 stars** — The standard control is present but applied inconsistently — right in most
  places, missing in identifiable spots.
- **4 stars** — The control is applied consistently, with minor hardening left undone.
- **5 stars** — Enforced structurally so a developer cannot easily omit it (middleware,
  type-level guarantees, parameterized APIs only, lint rules, CI gates), and verified by
  tests.

## 4. Calibrate

- **A single reachable critical vulnerability outweighs everything else.** Do not average it
  away: apply the caps below.
- Rate **enforcement, not intention**. Validation applied on 9 of 10 routes is a 3, not a 4 —
  attackers use the tenth.
- Distinguish **reachable** from **theoretical**. Mark each finding as Reachable (a path
  from untrusted input exists), Conditional (needs another precondition), or Defense-in-depth.
- Do not report a finding you cannot trace to a concrete line. No speculative "might be
  vulnerable" entries — they destroy trust in the whole report.
- Mixed evidence takes the lower band. Never round up.

### Hard caps
| Condition | Cap |
|---|---|
| Live secret committed to the repo or its history | **overall max 1** |
| Reachable injection (SQL/command/template) or RCE path | **overall max 1** |
| Missing or bypassable authorization on a sensitive endpoint | **overall max 1.5** |
| Known critical CVE in a production dependency with a patch available | **overall max 2.5** |
| PII or credentials written to logs | **overall max 3** |

5 stars overall requires every category at 4+, no reachable findings at any severity, and
evidence of ongoing practice: dependency scanning, secret scanning, and security tests in CI.

## 5. Report

Print the scorecard, save it to `.rate-my-code/security-report.md`, and append a row to
`.rate-my-code/history.md` (create with the header
`| Date | Type | Overall | Detail | Commit |` if missing).

```markdown
# Rate My Security — <project name>

**Overall: ★☆☆☆☆ 1.0 / 5** — Critical: one reachable issue needs fixing today.

| Category | Score | Weight |
|---|---|---|
| Secrets & Credential Handling | ★☆☆☆☆ 1 | 20% |
| Input Validation & Injection | ★★★☆☆ 3 | 20% |
| Authentication & Authorization | ★★★☆☆ 3 | 20% |
| Dependencies & Supply Chain | ★★★★☆ 4 | 15% |
| Data Protection | ★★★☆☆ 3 | 15% |
| Config & Deployment Hardening | ★★★☆☆ 3 | 10% |

**Surface reviewed:** 18 HTTP routes, 2 webhooks, 1 file upload, 1 queue consumer
**Tools run:** `npm audit` (1 high, 4 moderate) · `gitleaks` unavailable, checked manually
**Caps applied:** overall capped at 1.0 — live credential in `src/config/db.ts:14`
**Limitations:** static AI review of source only; no runtime or infrastructure testing.

## Fix today
## Fix this sprint
## Defense in depth
## What's already solid
```

Finding format, ID prefix `SEC`, ordered by severity then reachability:

```markdown
#### [SEC-01] Order lookup endpoint has no ownership check
- **Severity:** Critical · **Reachability:** Reachable · **Effort:** S · **Impact:** AuthZ +2 stars
- **Where:** `src/api/orders.ts:47` — `GET /orders/:id` loads by id with no user scope
- **Attack path:** Any authenticated user changes the `id` in the URL and reads any other
  customer's order, including their address and last four card digits.
- **Fix:** Scope the query to the session user (`where: { id, userId: session.userId }`) and
  return 404 rather than 403 to avoid confirming existence. Add a test asserting user A
  receives 404 for user B's order. Audit the other 6 `:id` routes for the same pattern.
```

Include a CWE or OWASP reference where it genuinely helps the reader, not as decoration.

## 6. Do no harm

- Never write a discovered secret into the report, the history file, or the terminal in
  full — redact to the first four characters and say where it lives.
- Never test a vulnerability against a live system.
- If a live credential is found, the first recommendation is always **rotate it**, because
  removing it from code does not remove it from history or from whoever already copied it.

## 7. Hand off

> SEC-01 is exploitable right now and takes about 20 minutes to fix. Want me to patch it and
> audit the other `:id` routes for the same pattern? I'd add a regression test with it.

Use the **`boost-my-score`** skill to apply fixes by ID. Security fixes get verified
individually — each one needs a test proving the attack path is closed before it counts as
resolved.
