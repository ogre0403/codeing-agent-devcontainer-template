#!/bin/sh
# macOS 的 ~/.docker/config.json 可能含有：
#   - credsStore: osxkeychain  → 容器內找不到此二進位
#   - currentContext: orbstack  → 指向 macOS 上的 socket，容器內無法連線
# 使用空的 config.json，讓 Docker 回退到預設 context (unix:///var/run/docker.sock)
TEMP_DOCKER_CONFIG=$(mktemp -d)
echo '{}' > "$TEMP_DOCKER_CONFIG/config.json"
export DOCKER_CONFIG="$TEMP_DOCKER_CONFIG"
exec devcontainer "$@"
