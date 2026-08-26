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
