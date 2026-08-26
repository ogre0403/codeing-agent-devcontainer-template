#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target="${ZDOTDIR:-$HOME}/.zshrc"
start_marker="# >>> codeing-agent-devcontainer: coding-agent >>>"
end_marker="# <<< codeing-agent-devcontainer: coding-agent <<<"

usage() {
  printf 'Usage: %s [--file SHELL_RC]\n' "$0"
  printf '\nInstall or update the repository shell helpers in a zsh rc file.\n'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --file)
      [ "$#" -ge 2 ] || { printf '%s\n' '--file requires a path' >&2; exit 2; }
      target=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

output_file=$(mktemp "${TMPDIR:-/tmp}/coding-agent-rc.XXXXXX")
trap 'rm -f "$output_file"' EXIT HUP INT TERM

target_dir=$(dirname -- "$target")
mkdir -p "$target_dir"

if [ -f "$target" ]; then
  awk -v start="$start_marker" -v end="$end_marker" '
    $0 == start { skipping=1; found=1; next }
    skipping && $0 == end { skipping=0; next }
    !skipping { print }
  ' "$target" > "$output_file"
else
  : > "$output_file"
fi

{
  printf '\n%s\n' "$start_marker"
  for source_file in \
    "$script_dir/devcontainer-aliases.zsh" \
    "$script_dir/coding-agent.zsh"; do
    [ -f "$source_file" ] || { printf 'Source file not found: %s\n' "$source_file" >&2; exit 1; }
    cat "$source_file"
    printf '\n'
  done
  printf '%s\n' "$end_marker"
} >> "$output_file"

mv "$output_file" "$target"
printf 'Installed coding-agent() in %s\n' "$target"
printf 'Run: source %s\n' "$target"
