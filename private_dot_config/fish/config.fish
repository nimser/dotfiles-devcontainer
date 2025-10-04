if status is-interactive
 
  # Note: use ~/.xsessionrc instead for env variables that need to be globally available outside shell 

  if test -d ~/.rd/bin
    set -gx fish_user_paths "$HOME/.rd/bin"
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
