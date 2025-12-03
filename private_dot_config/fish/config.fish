if status is-interactive

  # Note: use ~/.profile and ~/.xsessionrc instead for env variables that need to be globally available outside shell 

  # First login: decrypt encrypted chezmoi files
  if type -q chezmoi
    if command -v gpg > /dev/null; and gpg --list-secret-keys > /dev/null 2>&1
      if not test -f "$HOME/.config/fish/conf.d/secret.environment.fish"
        set_color green
        echo ">> First connection detected: Decrypting chezmoi secrets..."
        set_color normal
        chezmoi apply --include=encrypted
        set_color green
        echo ">> Secrets decrypted successfully."
        set_color normal
      end
    end
  end

  if test -d ~/.rd/bin
    set -gx --append fish_user_paths "$HOME/.rd/bin"
  end

  if type -q mise
    mise activate fish | source
  end

  if type -q direnv
    direnv hook fish | source
  end

  if type -q labctl
    labctl completion fish | source
  end
end
