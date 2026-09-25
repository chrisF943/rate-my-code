#!/usr/bin/env bash
# rate-my-code — install the star-rating review skills into every agentic coding
# tool you actually have.
#
# Run it with no arguments: it detects your installed agents and wires each one up.
# Claude Code gets the real plugin (marketplace + install) when its CLI is present;
# every other tool loads the same SKILL.md format, so installing there is a copy
# into the directory that tool scans. Nothing is compiled and nothing is fetched.

set -euo pipefail

SKILLS=(rate-my-code rate-my-pr rate-my-docs rate-my-tests rate-my-security boost-my-score)
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SRC_DIR="$REPO_ROOT/skills"
PLUGIN_NAME=rate-my-code
MARKETPLACE_NAME=rate-my-code

TOOLS=(claude codex gemini antigravity warp opencode cursor qwen cline droid)

SCOPE=global
DRY_RUN=0
UNINSTALL=0
ASSUME_YES=0
SKILLS_ONLY=0
EXPLICIT_DIR=""
REQUESTED=()

usage() {
  cat <<'EOF'
rate-my-code installer

Usage:
  ./install.sh                                  Detect your installed agents and wire them up
  ./install.sh --tool <name>[,<name>...] [...]  Install into specific tools
  ./install.sh --dir <path> [...]               Install into an explicit skills directory

Tools:
  claude       Claude Code         plugin via the claude CLI, else ~/.claude/skills
  codex        OpenAI Codex CLI    ~/.agents/skills           ./.agents/skills
  gemini       Gemini CLI          ~/.agents/skills           ./.agents/skills
  antigravity  Google Antigravity  ~/.agents/skills           ./.agents/skills
  warp         Warp                ~/.agents/skills           ./.agents/skills
  agents       Any tool that reads the .agents/skills standard (same paths)
  opencode     OpenCode            ~/.config/opencode/skills  ./.opencode/skills
  cursor       Cursor              ~/.cursor/skills           ./.cursor/skills
  qwen         Qwen Code           ~/.qwen/skills             ./.qwen/skills
  cline        Cline               ~/.cline/skills            ./.cline/skills
  droid        Factory Droid       ~/.factory/skills          ./.factory/skills
  all          Every tool listed above, detected or not

Options:
  --project      Install into the current directory instead of your home directory
  --dir PATH     Install into an explicit skills directory, for a tool not listed
  --skills-only  Copy skills into ~/.claude/skills instead of installing the plugin
  --dry-run      Print what would happen and change nothing
  --uninstall    Remove rate-my-code from the detected or named destinations
  -y, --yes      Skip the confirmation prompt
  -h, --help     Show this message

Examples:
  ./install.sh                         # detect everything and install
  ./install.sh --dry-run               # see what detection found, change nothing
  ./install.sh --tool codex
  ./install.sh --tool cursor,opencode --project
  ./install.sh --uninstall
  ./install.sh --dir ~/.config/some-agent/skills
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

label_for() {
  case $1 in
    claude)      echo "Claude Code" ;;
    codex)       echo "OpenAI Codex CLI" ;;
    gemini)      echo "Gemini CLI" ;;
    antigravity) echo "Google Antigravity" ;;
    warp)        echo "Warp" ;;
    opencode)    echo "OpenCode" ;;
    cursor)      echo "Cursor" ;;
    qwen)        echo "Qwen Code" ;;
    cline)       echo "Cline" ;;
    droid)       echo "Factory Droid" ;;
    agents)      echo ".agents/skills standard" ;;
    *)           echo "$1" ;;
  esac
}

# Print the skills directory for a tool at the current scope.
dest_for() {
  case "$1:$SCOPE" in
    claude:global)       printf '%s\n' "$HOME/.claude/skills" ;;
    claude:project)      printf '%s\n' "$PWD/.claude/skills" ;;
    codex:global|gemini:global|antigravity:global|warp:global|agents:global)      printf '%s\n' "$HOME/.agents/skills" ;;
    codex:project|gemini:project|antigravity:project|warp:project|agents:project) printf '%s\n' "$PWD/.agents/skills" ;;
    opencode:global)     printf '%s\n' "$HOME/.config/opencode/skills" ;;
    opencode:project)    printf '%s\n' "$PWD/.opencode/skills" ;;
    cursor:global)       printf '%s\n' "$HOME/.cursor/skills" ;;
    cursor:project)      printf '%s\n' "$PWD/.cursor/skills" ;;
    qwen:global)         printf '%s\n' "$HOME/.qwen/skills" ;;
    qwen:project)        printf '%s\n' "$PWD/.qwen/skills" ;;
    cline:global)        printf '%s\n' "$HOME/.cline/skills" ;;
    cline:project)       printf '%s\n' "$PWD/.cline/skills" ;;
    droid:global)        printf '%s\n' "$HOME/.factory/skills" ;;
    droid:project)       printf '%s\n' "$PWD/.factory/skills" ;;
    *) echo "unknown tool: $1" >&2; return 1 ;;
  esac
}

# Echo why a tool looks installed, or return 1 if we cannot find it.
detect_reason() {
  case $1 in
    claude)
      have claude && { echo "claude CLI"; return 0; }
      [ -d "$HOME/.claude" ] && { echo "~/.claude"; return 0; } ;;
    codex)
      have codex && { echo "codex CLI"; return 0; }
      [ -d "$HOME/.codex" ] && { echo "~/.codex"; return 0; } ;;
    gemini)
      have gemini && { echo "gemini CLI"; return 0; }
      [ -d "$HOME/.gemini" ] && { echo "~/.gemini"; return 0; } ;;
    antigravity)
      [ -d "$HOME/.antigravity" ] && { echo "~/.antigravity"; return 0; }
      [ -d "/Applications/Antigravity.app" ] && { echo "Antigravity.app"; return 0; } ;;
    warp)
      have warp && { echo "warp CLI"; return 0; }
      [ -d "$HOME/.warp" ] && { echo "~/.warp"; return 0; }
      [ -d "/Applications/Warp.app" ] && { echo "Warp.app"; return 0; } ;;
    opencode)
      have opencode && { echo "opencode CLI"; return 0; }
      [ -d "$HOME/.config/opencode" ] && { echo "~/.config/opencode"; return 0; } ;;
    cursor)
      have cursor-agent && { echo "cursor-agent CLI"; return 0; }
      [ -d "$HOME/.cursor" ] && { echo "~/.cursor"; return 0; }
      [ -d "/Applications/Cursor.app" ] && { echo "Cursor.app"; return 0; } ;;
    qwen)
      have qwen && { echo "qwen CLI"; return 0; }
      [ -d "$HOME/.qwen" ] && { echo "~/.qwen"; return 0; } ;;
    cline)
      [ -d "$HOME/.cline" ] && { echo "~/.cline"; return 0; }
      # Cline ships as an editor extension; its versioned directory is the only marker.
      for ext in "$HOME"/.vscode/extensions/saoudrizwan.claude-dev-* \
                 "$HOME"/.vscode-insiders/extensions/saoudrizwan.claude-dev-* \
                 "$HOME"/.cursor/extensions/saoudrizwan.claude-dev-*; do
        [ -d "$ext" ] && { echo "Cline editor extension"; return 0; }
      done ;;
    droid)
      have droid && { echo "droid CLI"; return 0; }
      [ -d "$HOME/.factory" ] && { echo "~/.factory"; return 0; } ;;
  esac
  return 1
}

run() {
  if [ $DRY_RUN -eq 1 ]; then
    echo "    would run: $*"
  else
    "$@"
  fi
}

# Copy (or remove) the six skill directories at a destination.
sync_skills() {
  local dest=$1
  for skill in "${SKILLS[@]}"; do
    local target="$dest/$skill"
    if [ $UNINSTALL -eq 1 ]; then
      if [ -e "$target" ]; then
        echo "    remove $skill"
        [ $DRY_RUN -eq 0 ] && rm -rf "$target"
      else
        echo "    skip   $skill (not installed)"
      fi
      continue
    fi
    local verb=install
    [ -e "$target" ] && verb=replace
    echo "    $verb $skill"
    if [ $DRY_RUN -eq 0 ]; then
      mkdir -p "$dest"
      rm -rf "$target"
      cp -R "$SRC_DIR/$skill" "$target"
    fi
  done
}

# Claude Code's native path: register this checkout as a marketplace, install the plugin.
install_claude_plugin() {
  if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE_NAME"; then
    echo "    marketplace $MARKETPLACE_NAME already registered — updating"
    run claude plugin marketplace update "$MARKETPLACE_NAME"
  else
    echo "    register marketplace from $REPO_ROOT"
    run claude plugin marketplace add "$REPO_ROOT" --scope user
  fi
  echo "    install plugin $PLUGIN_NAME"
  run claude plugin install "$PLUGIN_NAME@$MARKETPLACE_NAME"
}

uninstall_claude_plugin() {
  if claude plugin list 2>/dev/null | grep -q "$PLUGIN_NAME"; then
    echo "    uninstall plugin $PLUGIN_NAME"
    run claude plugin uninstall "$PLUGIN_NAME"
  else
    echo "    skip   plugin $PLUGIN_NAME (not installed)"
  fi
  if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE_NAME"; then
    echo "    remove marketplace $MARKETPLACE_NAME"
    run claude plugin marketplace remove "$MARKETPLACE_NAME"
  fi
}

# Wire up one tool, choosing plugin or skills-copy for Claude Code.
apply_tool() {
  local tool=$1
  echo
  echo "  $(label_for "$tool")"
  if [ "$tool" = claude ] && [ $SKILLS_ONLY -eq 0 ] && [ $SCOPE = global ] && have claude; then
    if [ $UNINSTALL -eq 1 ]; then
      uninstall_claude_plugin
    else
      install_claude_plugin
    fi
    return
  fi
  local dest
  dest=$(dest_for "$tool")
  echo "    → $dest"
  sync_skills "$dest"
}

while [ $# -gt 0 ]; do
  case $1 in
    --tool)
      [ $# -ge 2 ] || { echo "--tool needs a value" >&2; exit 2; }
      IFS=',' read -r -a parsed <<< "$2"
      REQUESTED+=("${parsed[@]}")
      shift 2 ;;
    --dir)
      [ $# -ge 2 ] || { echo "--dir needs a value" >&2; exit 2; }
      EXPLICIT_DIR=$2
      shift 2 ;;
    --project)     SCOPE=project; shift ;;
    --global)      SCOPE=global; shift ;;
    --skills-only) SKILLS_ONLY=1; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    --uninstall)   UNINSTALL=1; shift ;;
    -y|--yes)      ASSUME_YES=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; echo >&2; usage >&2; exit 2 ;;
  esac
done

[ -d "$SRC_DIR" ] || { echo "cannot find skills at $SRC_DIR — run this from the repo" >&2; exit 1; }

action=install
[ $UNINSTALL -eq 1 ] && action=uninstall

# Expand `all`, then fall back to detection when no tool was named.
SELECTED=()
for tool in ${REQUESTED[@]+"${REQUESTED[@]}"}; do
  if [ "$tool" = all ]; then
    SELECTED+=("${TOOLS[@]}")
  else
    dest_for "$tool" >/dev/null   # validates the name, exits on a typo
    SELECTED+=("$tool")
  fi
done

DETECTING=0
if [ ${#SELECTED[@]} -eq 0 ] && [ -z "$EXPLICIT_DIR" ]; then
  DETECTING=1
  echo "Looking for installed agents…"
  echo
  for tool in "${TOOLS[@]}"; do
    if reason=$(detect_reason "$tool"); then
      printf '  found    %-20s (%s)\n' "$(label_for "$tool")" "$reason"
      SELECTED+=("$tool")
    else
      printf '  missing  %-20s\n' "$(label_for "$tool")"
    fi
  done
  echo
  if [ ${#SELECTED[@]} -eq 0 ]; then
    echo "No supported agent found. Point the installer at your tool's skills folder:"
    echo "  ./install.sh --dir ~/.config/your-agent/skills"
    exit 1
  fi
fi

# De-duplicate: codex, antigravity and agents share one skills directory, and a
# tool named twice should only be wired once.
UNIQUE_TOOLS=()
for tool in ${SELECTED[@]+"${SELECTED[@]}"}; do
  key=$tool
  if [ "$tool" != claude ]; then
    key=$(dest_for "$tool")   # collapse tools that share a destination
  fi
  seen=0
  for known in ${SEEN_KEYS[@]+"${SEEN_KEYS[@]}"}; do
    [ "$known" = "$key" ] && seen=1 && break
  done
  if [ $seen -eq 0 ]; then
    SEEN_KEYS=(${SEEN_KEYS[@]+"${SEEN_KEYS[@]}"} "$key")
    UNIQUE_TOOLS+=("$tool")
  else
    echo "  (${tool} shares its skills directory with a tool already selected — skipping)"
  fi
done

if [ $DETECTING -eq 1 ] && [ $DRY_RUN -eq 0 ] && [ $ASSUME_YES -eq 0 ] && [ -t 0 ]; then
  printf '%s rate-my-code into %d tool(s)? [Y/n] ' "$(tr '[:lower:]' '[:upper:]' <<< "${action:0:1}")${action:1}" "${#UNIQUE_TOOLS[@]}"
  read -r answer
  case $answer in
    ''|y|Y|yes|YES) ;;
    *) echo "Cancelled."; exit 0 ;;
  esac
fi

[ $DRY_RUN -eq 1 ] && { echo "dry run — nothing will be written"; }

echo
echo "${action}ing rate-my-code:"

if [ -n "$EXPLICIT_DIR" ]; then
  echo
  echo "  $EXPLICIT_DIR"
  sync_skills "$EXPLICIT_DIR"
fi

for tool in ${UNIQUE_TOOLS[@]+"${UNIQUE_TOOLS[@]}"}; do
  apply_tool "$tool"
done

echo
if [ $UNINSTALL -eq 1 ]; then
  echo "Done. Restart your agents so they stop listing the skills."
else
  echo "Done. Restart your agents, then ask one to \"rate my code\"."
fi
