coding-agent() {
  local dir_name="${PWD:t}"
  local container_name="${dir_name//[^a-zA-Z0-9_.-]/-}"
  if [[ "$container_name" != [a-zA-Z0-9]* ]]; then
    container_name="coding-agent-$container_name"
  fi
  container_name="${container_name}-$(date '+%Y-%m%d-%H%M%S')"
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
    --name="$container_name" \
    -v vscocde-golang-devcontainer:/root/go \
    -v opencode_setting:/root/.local \
    -v claude_setting:/root/.claude_setting \
    -v codex_setting:/root/.codex \
    -v agent_setting:/root/.agents \
    -v "$PWD":/workspaces/"$dir_name" \
    "${workspace_mounts[@]}" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /workspaces/"$dir_name" \
    -e WORKSPACE_FOLDER=/workspaces/"$dir_name" \
    -e AWS_BEARER_TOKEN_BEDROCK \
    -e AZURE_OPENAI_API_KEY \
    -e AZURE_COGNITIVE_SERVICES_RESOURCE_NAME \
    -e HOST_PROJECT_PATH="$PWD" \
    codeing-agent-devcontainer:standalone || return

  if (( ${#networks} > 1 )); then
    local network
    for network in "${networks[2,-1]}"; do
      docker network connect "$network" "$container_name" || {
        docker rm -f "$container_name" >/dev/null
        return 1
      }
    done
  fi

  docker attach "$container_name"
}
