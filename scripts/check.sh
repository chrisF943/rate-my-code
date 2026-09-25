#!/usr/bin/env bash
# Everything CI would run, in one command. No dependencies beyond bash and python3.
set -euo pipefail

cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

fail=0
note() { printf '  %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; fail=1; }

echo "JSON manifests"
for f in .claude-plugin/*.json .agents/plugins/*.json .codex-plugin/*.json .cursor-plugin/*.json; do
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>/dev/null; then
    note "ok    $f"
  else
    bad "$f is not valid JSON"
  fi
done

echo
echo "Version sync"
versions=$(python3 - <<'PY'
import json
files = {
    ".claude-plugin/plugin.json":      lambda d: d["version"],
    ".claude-plugin/marketplace.json": lambda d: d["plugins"][0]["version"],
    ".codex-plugin/plugin.json":       lambda d: d["version"],
    ".cursor-plugin/plugin.json":      lambda d: d["version"],
}
for path, pick in files.items():
    with open(path) as fh:
        print(f"{pick(json.load(fh))} {path}")
PY
)
printf '%s\n' "$versions" | while read -r v f; do note "$v  $f"; done
if [ "$(printf '%s\n' "$versions" | awk '{print $1}' | sort -u | wc -l)" -ne 1 ]; then
  bad "manifest versions disagree — run ./scripts/bump-version.sh <version>"
fi

echo
echo "Skill frontmatter"
for dir in skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  [ -f "$file" ] || { bad "$name has no SKILL.md"; continue; }
  if report=$(python3 - "$file" "$name" 2>&1 <<'PY'
import re, sys
path, expected = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
if not match:
    sys.exit("no YAML frontmatter delimited by ---")
fields, problems = {}, []
for line in match.group(1).split("\n"):
    key, sep, value = line.partition(":")
    if not sep:
        problems.append(f"unparsable frontmatter line: {line!r}")
    else:
        fields[key.strip()] = value.strip()
extra = set(fields) - {"name", "description"}
if extra:
    problems.append(f"unexpected frontmatter keys: {sorted(extra)}")
if fields.get("name") != expected:
    problems.append(f"name {fields.get('name')!r} != directory {expected!r}")
if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", fields.get("name", "")):
    problems.append("name is not lowercase kebab-case")
description = fields.get("description", "")
if not description:
    problems.append("description is empty")
elif len(description) > 1024:
    problems.append(f"description is {len(description)} chars, limit is 1024")
if problems:
    sys.exit("; ".join(problems))
print(len(description))
PY
  ); then
    note "ok    $name (description $report chars)"
  else
    bad "$name: $report"
  fi
done

echo
echo "Installer"
bash -n install.sh && note "ok    install.sh parses"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck install.sh scripts/*.sh && note "ok    shellcheck"
else
  note "skip  shellcheck not installed"
fi

echo
if [ $fail -eq 0 ]; then
  echo "All checks passed."
else
  echo "Checks failed."
  exit 1
fi
