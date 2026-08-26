CODING_AGENT_IMAGE ?= codeing-agent-devcontainer:standalone
INSTALL_PYTHON ?= false
GO_VERSION ?= 1.22.4
GIT_USER_NAME ?= $(shell git config --get user.name)
GIT_USER_EMAIL ?= $(shell git config --get user.email)

DEVCONTAINER_IMAGE ?= devcontainer-cli

.PHONY: build-coding-agent build-devcontainer

build-coding-agent:
	docker build \
		--build-arg INSTALL_PYTHON=$(INSTALL_PYTHON) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg GIT_USER_NAME="$(GIT_USER_NAME)" \
		--build-arg GIT_USER_EMAIL="$(GIT_USER_EMAIL)" \
		-f agent/Dockerfile \
		-t $(CODING_AGENT_IMAGE) \
		agent


build-devcontainer:
	docker build \
	-f devcontainer/Dockerfile \
	-t $(DEVCONTAINER_IMAGE) \
	devcontainer
