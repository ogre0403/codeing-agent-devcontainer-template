# Devcontainer AI Workbench

This repository provides a templates of `tmux`-based AI workbench inside the devcontainer.


## Run Devcontainer CLI in Container

```shell
docker build -t devcontainer-cli .
```
Add shell is shell dot file.

```shell
alias devcontainer-stop='docker stop $(docker ps -q -f label=devcontainer.local_folder="$PWD")'
alias devcontainer-remove='docker rm $(docker ps -a -q -f label=devcontainer.local_folder="$PWD")'

devcontainer() {
  docker run --rm -it \
    -v "$HOME":"$HOME":ro \
    -v "$HOME/.docker/buildx" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w "$PWD" \
    -e HOME="$HOME" \
    -e GEMINI_API_KEY="$GEMINI_API_KEY" \
    -e AWS_BEARER_TOKEN_BEDROCK="$AWS_BEARER_TOKEN_BEDROCK" \
    -e AZURE_OPENAI_API_KEY="$AZURE_OPENAI_API_KEY" \
    -e AZURE_COGNITIVE_SERVICES_RESOURCE_NAME="$AZURE_COGNITIVE_SERVICES_RESOURCE_NAME" \
    devcontainer-cli "$@"
}
```


## Rebuild the devcontainer

After pulling the latest `.devcontainer` changes, rebuild the container in VS Code.

## Terminal profiles

- `zsh`: normal login shell inside the devcontainer
- `tmux-ai`: starts or re-attaches the shared `tmux` session for AI coding

Open `tmux-ai` from the VS Code terminal profile menu, or run the launcher manually inside the container:

```shell
./.devcontainer/start-ai-workbench.sh
```

## tmux session layout

The launcher creates or re-attaches the `ai-workbench` session with 6 windows:

1. `work`
2. `claude`
3. `opencode`
4. `codex`
5. `gemini`
6. `ops`

Every `tmux` window and pane uses `zsh -l` by default.

The AI agent windows start their CLI once automatically. When an agent exits, the same tmux window stays open and drops back to a shell so you can run the agent again manually.

The devcontainer installs the full `less` package and sets `PAGER` and `GIT_PAGER` to `less -FRX`, so commands like `git diff` keep ANSI colors in both normal terminals and tmux windows.

## Useful tmux commands

```shell
# re-attach from a normal shell
tmux attach -t ai-workbench

# list sessions
tmux ls
```

- Prefix key: `Ctrl-a`
- Detach from the current session: `Ctrl-a d`
- Show the window list: `Ctrl-a w`
- Reload the repo-managed tmux config: `Ctrl-a r`
- Horizontal split: `Ctrl-a _`
- Vertical split: `Ctrl-a |`

If an AI CLI is not available in the container, its window stays open in `zsh` and shows a short error message instead of failing the whole session.

