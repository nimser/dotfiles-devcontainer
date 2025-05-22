set -gx GPGID "0x03BC4AD253B82986"

if not set -q SSH_AUTH_SOCK # This may already be set by a devcontainer environment
  set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
  gpgconf --launch gpg-agent
end

set -gx GPG_TTY (tty)
