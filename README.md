# Devcontainer AI Workbench

This repository provides a templates of `tmux`-based AI workbench inside the devcontainer.


## Run Devcontainer CLI in Container

```shell
cd devcontainer
docker build -t devcontainer-cli .
```
Add shell is shell dot file.

```shell
alias devcontainer-stop='docker stop $(docker ps -q -f label=devcontainer.local_folder="$PWD")'
alias devcontainer-remove='docker rm $(docker ps -a -q -f label=devcontainer.local_folder="$PWD")'

devcontainer() {
  docker run --rm -it \
    -v "$HOME":"$HOME":ro \
    -v "$PWD":"$PWD":rw \
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


```shell
coding-agent() {
  # 取得目前目錄的名稱 (例如 /Users/user/project-abc 會得到 project-abc)
  local dir_name="${PWD:t}"
  local networks=()
  local workspace_volumes=()
  local docker_run_args=(docker run --rm -dit)

  while (( $# > 0 )); do
    case "$1" in
      --network)
        if (( $# < 2 )) || [[ -z "$2" ]]; then
          print -u2 "coding-agent: --network requires a network name"
          return 2
        fi
        networks+=("$2")
        shift 2
        ;;
      --workspace-volume)
        if (( $# < 2 )) || [[ -z "$2" ]]; then
          print -u2 "coding-agent: --workspace-volume requires a directory path"
          return 2
        fi

        local host_path="${2:A}"
        local workspace_name="${host_path:t}"
        if [[ -z "$workspace_name" ]]; then
          print -u2 "coding-agent: --workspace-volume path must name a directory"
          return 2
        fi

        # Docker destinations must be unique when multiple paths share a name.
        local existing_volume
        for existing_volume in "${workspace_volumes[@]}"; do
          if [[ "${existing_volume##*|}" == "$workspace_name" ]]; then
            print -u2 "coding-agent: duplicate workspace directory name: $workspace_name"
            return 2
          fi
        done
        workspace_volumes+=("$host_path|$workspace_name")
        shift 2
        ;;
      *)
        print -u2 "coding-agent: unknown option: $1"
        return 2
        ;;
    esac
  done

  # 第一個 network 在建立容器時加入，其餘 network 在容器啟動後加入。
  if (( ${#networks} > 0 )); then
    docker_run_args+=(--network "${networks[1]}")
  fi

  local workspace_mounts=()
  local workspace_volume
  for workspace_volume in "${workspace_volumes[@]}"; do
    local host_path="${workspace_volume%%|*}"
    local workspace_name="${workspace_volume##*|}"
    workspace_mounts+=(--mount "type=bind,source=$host_path,target=/workspaces/$workspace_name,readonly")
  done

  "${docker_run_args[@]}" \
    --security-opt=seccomp=unconfined \
    --name="$dir_name" \
    -v vscocde-golang-devcontainer:/root/go \
    -v opencode_setting:/root/.local \
    -v claude_setting:/root/.claude_setting \
    -v codex_setting:/root/.codex \
    -v "$PWD":/workspaces/"$dir_name" \
    "${workspace_mounts[@]}" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /workspaces/"$dir_name" \
    -e WORKSPACE_FOLDER=/workspaces/"$dir_name" \
    -e AWS_BEARER_TOKEN_BEDROCK \
    -e AZURE_OPENAI_API_KEY \
    -e AZURE_COGNITIVE_SERVICES_RESOURCE_NAME \
    codeing-agent-devcontainer:standalone || return

  if (( ${#networks} > 1 )); then
    local network
    for network in "${networks[2,-1]}"; do
      docker network connect "$network" "$dir_name" || {
        docker rm -f "$dir_name" >/dev/null
        return 1
      }
    done
  fi

  docker attach "$dir_name"
}
```

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
