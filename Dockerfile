FROM node:20-alpine

# 安裝 Docker CLI, Docker Compose 外掛以及 Git (Dev Container 常用到 git)
RUN apk update && \
    apk add --no-cache docker-cli docker-cli-buildx docker-cli-compose git

# 全域安裝 Dev Container CLI
RUN npm install -g @devcontainers/cli

# 設定進入點
ENTRYPOINT ["devcontainer"]