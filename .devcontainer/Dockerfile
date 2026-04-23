FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

COPY --from=jdxcode/mise /usr/local/bin/mise /usr/local/bin/

# install x11-utils and make sure mise is activated in both zsh and bash.
RUN apt-get -y update && apt-get install -y --no-install-recommends x11-utils && \
    echo 'eval "$(mise activate bash)"' >> /home/vscode/.bashrc && \
    echo 'eval "$(mise activate zsh)"' >> /home/vscode/.zshrc
