# Security

## What `rate-my-security` is, and is not

It is a static review performed by an AI reading your source. It reliably finds common,
real classes of vulnerability, and every report it writes says so plainly.

It is **not** a penetration test. It does not execute attacks, it does not observe your
running system, and **it cannot prove a vulnerability is absent**. A 5-star security
rating means nothing obviously wrong was found by reading the code — it is not a
certification. For anything handling money, health data, or credentials at scale, use it
to supplement a professional audit, never to replace one.

## What the skills do to your machine

- The five `rate-my-*` skills are **read-only**. They read files and run your project's
  own commands — the lint, typecheck, test, build and audit scripts already defined in
  your project — to gather evidence. They do not modify source.
- `boost-my-score` edits files, and only after you choose a batch of findings by ID.
- Reports are written to `.rate-my-code/` in your project. Nothing is sent anywhere.
- There is no telemetry, no network calls, and no dependencies.

Your agent's own permission settings still apply. If you do not want a skill running your
test suite, deny the command when your agent asks.

## Reporting a vulnerability

If you find a problem in this repo — a prompt injection that turns a read-only rater into
something that writes or exfiltrates, an installer path that escapes its destination,
anything of that shape — please report it privately through GitHub's **Report a
vulnerability** button on the Security tab rather than opening a public issue.

Include what you ran, what happened, and which harness you were using. I will confirm
receipt and tell you whether I consider it in scope.
