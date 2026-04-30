FROM node:20-alpine

# 安裝 Docker CLI, Docker Compose 外掛以及 Git (Dev Container 常用到 git)
RUN apk update && \
    apk add --no-cache docker-cli docker-cli-buildx docker-cli-compose git

# 全域安裝 Dev Container CLI
RUN npm install -g @devcontainers/cli

# 複製並設定 entrypoint 腳本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 設定進入點
ENTRYPOINT ["/entrypoint.sh"]