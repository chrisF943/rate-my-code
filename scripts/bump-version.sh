#!/usr/bin/env bash
# Set the version in every manifest at once, so they cannot drift.
#   ./scripts/bump-version.sh 0.2.0
set -euo pipefail

cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

version=${1:-}
case $version in
  '')                              echo "usage: ./scripts/bump-version.sh <version>" >&2; exit 2 ;;
  [0-9]*.[0-9]*.[0-9]*)            ;;
  *)                               echo "not a semver version: $version" >&2; exit 2 ;;
esac

python3 - "$version" <<'PY'
import json, sys

version = sys.argv[1]

def edit(path, mutate):
    with open(path) as fh:
        data = json.load(fh)
    mutate(data)
    with open(path, "w") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
    print(f"  {version}  {path}")

def set_version(data):
    data["version"] = version

def set_plugin_versions(data):
    for plugin in data["plugins"]:
        plugin["version"] = version

edit(".claude-plugin/plugin.json", set_version)
edit(".claude-plugin/marketplace.json", set_plugin_versions)
edit(".codex-plugin/plugin.json", set_version)
edit(".cursor-plugin/plugin.json", set_version)
PY

echo
echo "Now add a $version section to CHANGELOG.md."
