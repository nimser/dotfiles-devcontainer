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

# Pre-create named-volume mountpoints owned by vscode. When Docker seeds a
# fresh named volume (devpod-cache / devpod-mise) it copies ownership from
# the image path; without this the mountpoint is created root:root and every
# cache write (chezmoi, nix, mise) fails with 'permission denied'.
RUN mkdir -p /home/vscode/.cache /home/vscode/.local/share/mise && \
    chown -R vscode:vscode /home/vscode/.cache /home/vscode/.local

# install x11-utils and make sure mise is activated in both zsh and bash.
RUN apt-get -y update && apt-get install -y --no-install-recommends x11-utils && \
    rm -rf /var/lib/apt/lists/* && \
    echo 'eval "$(mise activate bash)"' >> /home/vscode/.bashrc && \
    echo 'eval "$(mise activate zsh)"' >> /home/vscode/.zshrc
