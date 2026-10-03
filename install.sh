#!/usr/bin/env bash
set -euo pipefail

# Symlink every skill in this catalog into a tool's skills directory.
#
#   ./install.sh                 -> ~/.claude/skills   (Claude Code + OpenCode)
#   ./install.sh --opencode      -> ~/.config/opencode/skills
#   ./install.sh --target DIR    -> DIR
#   ./install.sh --uninstall     -> remove the links this script created

catalog="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude/skills"
uninstall=0

while [ $# -gt 0 ]; do
  case "$1" in
    --opencode) dest="$HOME/.config/opencode/skills" ;;
    --claude)   dest="$HOME/.claude/skills" ;;
    --target)   dest="$2"; shift ;;
    --uninstall) uninstall=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

count=0
for dir in "$catalog"/*/; do
  name="$(basename "$dir")"
  [ -f "$dir/SKILL.md" ] || continue
  link="$dest/$name"

  if [ "$uninstall" = "1" ]; then
    if [ -L "$link" ]; then
      target="$(readlink "$link")"
      case "$target" in
        "$catalog"/*) rm "$link" && echo "removed $link" ;;
        *) echo "kept $link (does not point into this catalog)" ;;
      esac
    fi
    continue
  fi

  mkdir -p "$dest"
  ln -sfn "${dir%/}" "$link"
  echo "linked $name -> $link"
  count=$((count + 1))
done

if [ "$uninstall" = "1" ]; then
  echo "uninstall done"
else
  echo "installed $count skill(s) into $dest"
  echo "note: restart the agent session so the skills get discovered"
fi
