function ssh --description "Wrapper for ssh: changes bg color and uses gpg agent"
  set -l default_bg "#000000"
  set -l remote_bg "#502836"
  set -l color_restore_needed false



  if command -v alacritty >/dev/null 2>&1; and alacritty msg --help >/dev/null 2>&1
    command alacritty msg config "colors.primary.background='$remote_bg'"
    if test $status -eq 0
      set color_restore_needed true
    end
  end
  # This gpg-connect-agent wrapper ensures any terminal-based pinentry appears in the curently active terminal window
  if test $DEVPOD != "true"
    gpg-connect-agent updatestartuptty /bye
  end
  command ssh $argv
  set -l ssh_exit_status $status
  if $color_restore_needed
    alacritty msg config "colors.primary.background='$default_bg'"
  end
  return $ssh_exit_status
end
