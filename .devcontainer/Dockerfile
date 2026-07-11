FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Install a pinned mise release (~10MB download) instead of
# `COPY --from=jdxcode/mise` which pulled the whole ~600MB image and — being
# `latest` — changed digest every few days, invalidating every following
# build layer (apt, devcontainer features, nix) on each rebuild.
# Bump the version here deliberately; mise self-manages tool versions anyway.
ARG MISE_VERSION=v2026.7.5
RUN curl -fsSL https://mise.run \
    | MISE_VERSION=${MISE_VERSION} MISE_INSTALL_PATH=/usr/local/bin/mise MISE_QUIET=1 sh \
    && mise --version

# Named volumes (devpod-cache, devpod-mise) inherit ownership from the image
# path they mount over; a missing path is created root:root and every cache
# write fails. Pre-create them owned by vscode, along with ~/.ssh (devpod key
# injection) and the age-plugin bridge state dirs.
RUN mkdir -p /home/vscode/.cache /home/vscode/.local/share/mise \
      /home/vscode/.ssh \
      /home/vscode/.local/state/age-plugin-tpm \
      /home/vscode/.local/state/age-plugin-yubikey && \
    chown -R vscode:vscode /home/vscode/.cache /home/vscode/.local /home/vscode/.ssh && \
    chmod 700 /home/vscode/.ssh

# Single apt update/install/cleanup, then activate mise in zsh and bash.
RUN apt-get -y update && apt-get install -y --no-install-recommends \
        x11-utils \
        fonts-liberation \
        fonts-noto-core \
        fontconfig && \
    rm -rf /var/lib/apt/lists/* && \
    fc-cache -fv && \
    echo 'eval "$(mise activate bash)"' >> /home/vscode/.bashrc && \
    echo 'eval "$(mise activate zsh)"' >> /home/vscode/.zshrc

CMD ["fc-list"]
