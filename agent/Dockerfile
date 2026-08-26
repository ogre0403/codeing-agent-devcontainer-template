FROM node:26-alpine

ARG INSTALL_PYTHON=false
ARG GO_VERSION=1.24.5
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
ARG TARGETARCH

RUN sed -i 's|https://dl-cdn.alpinelinux.org/alpine|https://alpine.cs.nycu.edu.tw|g' /etc/apk/repositories

RUN apk add --no-cache \
		bash \
		bubblewrap \
		curl \
		docker \
		docker-compose \
		git \
		lazygit \
		less \
		make \
		ripgrep \
		tmux \
		tzdata \
		zsh-vcs && \
	sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
	-t agnoster \
	-p git \
	-p z \
	-p terraform \
	-p virtualenv \
	-p https://github.com/zsh-users/zsh-autosuggestions \
	-a 'export TERM=xterm-256color' \
	-a 'export PAGER="less -FRX"' \
	-a 'export GIT_PAGER="less -FRX"' \
	-a 'export LESS="FRX"' \
	-a 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=2"' \
	-a 'AGNOSTER_CONTEXT_BG=52' \
	-a 'AGNOSTER_CONTEXT_FG=white' \
	-a 'AGNOSTER_DIR_BG=cyan' \
	-a 'AGNOSTER_DIR_FG=black' \
	-p https://github.com/zsh-users/zsh-completions

ENV TZ="Asia/Taipei"

RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
	echo ${TZ} > /etc/timezone

RUN test -n "${GIT_USER_NAME}" && test -n "${GIT_USER_EMAIL}" && \
	git config --global user.name "${GIT_USER_NAME}" && \
	git config --global user.email "${GIT_USER_EMAIL}" && \
	git config --global alias.st status && \
	git config --global alias.br branch

RUN sed -i '/## Main/i prompt_newline() { \n\
 if [[ -n $CURRENT_BG ]]; then\n\
   echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR\n\
%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"\n\
 else\n\
   echo -n " %{%k%}"\n\
 fi\n\
 echo -n " %{%f%}"\n\
 CURRENT_BG=''\n\
}' /root/.oh-my-zsh/themes/agnoster.zsh-theme && \
	sed -i 's/  prompt_hg/  prompt_hg\n  prompt_newline/' /root/.oh-my-zsh/themes/agnoster.zsh-theme

# A bind-mounted workspace can change between _make's readability check and
# its input redirection. Do not show a completion error in that race.
RUN sed -i 's|_make-parseMakefile < \$file|_make-parseMakefile < "\$file" 2>/dev/null|g' \
	/usr/share/zsh/functions/Completion/Unix/_make

RUN if [ "${INSTALL_PYTHON}" == "true" ]; then \
		apk add --no-cache python3 py3-pip; \
		python3 -m venv /root/.venv; \
		/root/.venv/bin/pip install git+https://opendev.org/openstack/python-openstackclient@stable/2025.1; \
	fi

RUN case "${TARGETARCH}" in \
		amd64) go_arch=amd64 ;; \
		arm64) go_arch=arm64 ;; \
		*) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
	esac && \
	curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" \
		| tar -C /usr/local -xz

RUN npm install --global \
		@anthropic-ai/claude-code \
		@fission-ai/openspec@latest \
		@openai/codex && \
	curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path

RUN npm install -g @officecli/officecli && \
    apk add icu-libs

ENV PATH="/usr/local/go/bin:/root/.opencode/bin:/root/.local/bin:${PATH}" \
	LANG="C.UTF-8" \
	LANGUAGE="C.UTF-8" \
	LC_CTYPE="C.UTF-8" \
	LC_ALL="C.UTF-8" \
	CLAUDE_CODE_USE_BEDROCK="1"

RUN for profile in /root/.profile /root/.zprofile /root/.zshrc; do \
		printf '%s\n' 'export PATH="/usr/local/go/bin:/root/.opencode/bin:/root/.local/bin:$PATH"' >> "$profile"; \
	done && \
	printf '%s\n' 'if [ -f /root/.venv/bin/activate ]; then . /root/.venv/bin/activate; fi' >> /root/.zprofile

RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh \
    | sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-musl/g' \
    | sh && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

COPY tmux.conf /root/.tmux.conf

COPY entrypoint.sh /usr/local/bin/agent-entrypoint
COPY install_skills.sh /usr/local/bin/install_skills.sh

RUN chmod +x /usr/local/bin/agent-entrypoint && \
	chmod +x /usr/local/bin/install_skills.sh

VOLUME ["/root/.local", "/root/.claude_setting", "/root/.codex"]

ENTRYPOINT ["/usr/local/bin/agent-entrypoint"]
CMD ["/usr/bin/tmux"]
