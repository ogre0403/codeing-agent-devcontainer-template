#!/bin/sh

set -eu

WORKSPACE_FOLDER="${WORKSPACE_FOLDER:-/workspace}"
export TERM=xterm-256color

mkdir -p /root/.agents/skills /root/.config/openspec


mkdir -p /root/.claude_setting/claude
ln -sfn /root/.claude_setting/claude /root/.claude
ln -sfn /root/.claude_setting/.claude.json /root/.claude.json
ln -sfn /root/.agents/skills /root/.claude/skills

if [ -d "$WORKSPACE_FOLDER" ]; then
    git config --global color.ui auto
    git config --global core.pager 'less -FRX'
    git config --global alias.st status
    git config --global alias.br branch
fi

rtk telemetry disable
rtk init -g --codex
rtk init -g --copilot
rtk init -g --opencode
rtk init -g

if [ "$#" -eq 0 ]; then
    set -- /usr/bin/tmux
fi

exec "$@"
