if status is-interactive
  if test -d ~/.local/bin
    set -gx fish_user_paths $fish_user_paths ~/.local/bin
  end

  if test -d ~/.local/distrobox/bin
    set -gx fish_user_paths $fish_user_paths ~/.local/distrobox/bin
  end

  set -gx PNPM_HOME "/home/owner/.local/share/pnpm"
  if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
  end

  if test -d ~/.rd/bin
    set -gx --prepend fish_user_paths "$HOME/.rd/bin"
  end
  if type -q mise
    mise activate fish | source
  end
  if type -q direnv
    direnv hook fish | source
  end
end
