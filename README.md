# Devcontainer AI Workbench

This repository provides a templates of `tmux`-based AI workbench inside the devcontainer.


## Run Devcontainer CLI in Container

```shell
cd devcontainer
docker build -t devcontainer-cli .
```
Add `scripts/devcontainer-aliases.zsh` to a shell dot file, or use the install
script described below.


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



## aaa

```shell
docker build \
  --build-arg INSTALL_PYTHON=false \
  -f agent/Dockerfile \
  -t codeing-agent-devcontainer:standalone .
```

`make build-coding-agent` reads `user.name` and `user.email` from the host
Git configuration and writes them to the agent image's `/root/.gitconfig`.
Override them explicitly when needed:

```shell
make build-coding-agent GIT_USER_NAME="Your Name" GIT_USER_EMAIL="you@example.com"
```

```shell
docker run --rm -it \
  --security-opt=seccomp=unconfined \
  -v opencode_setting:/root/.local \
  -v claude_setting:/root/.claude_setting \
  -v codex_setting:/root/.codex \
  -v "$PWD":/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w /workspace \
  -e WORKSPACE_FOLDER=/workspace \
  codeing-agent-devcontainer:standalone
```


The `coding-agent()` implementation is maintained in `scripts/coding-agent.zsh`.

不帶 `--network` 時使用 Docker 的預設 network。可重複指定 `--network` 來連接
多個 container network：

```shell
coding-agent --network backend-network
coding-agent --network backend-network --network monitoring-network
```

可使用 `--workspace-volume` 將 host 目錄掛載到容器的 `/workspaces` 下，目錄名稱
沿用 host 目錄的 basename。參數可重複指定，也接受相對路徑和絕對路徑：

```shell
coding-agent --workspace-volume ../shared-lib \
  --workspace-volume /Users/user/another-project
```

上例會分別掛載到 `/workspaces/shared-lib` 和 `/workspaces/another-project`。

### Install or update `coding-agent()`

Use the repository script to install the function into zsh. Running it again
updates the managed block instead of adding a duplicate:

```shell
./scripts/install-coding-agent.sh
source ~/.zshrc
```

To use another zsh configuration file:

```shell
./scripts/install-coding-agent.sh --file ~/.config/zsh/.zshrc
```
