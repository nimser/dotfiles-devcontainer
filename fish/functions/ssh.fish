function ssh --description "Wrapper for ssh: changes bg color and uses gpg agent"
  set -l default_bg "#282A36"  # IMPORTANT: Replace with your ACTUAL default background
  set -l remote_bg "#502836"   # Replace with your desired background for SSH sessions

  if not command -v alacritty >/dev/null 2>&1; or not alacritty msg --help >/dev/null 2>&1
      echo "Alacritty runtime messaging ('alacritty msg') not available." >&2
      echo "Running ssh without color change." >&2
      command ssh $argv
      return $status
  end
  alacritty msg config -w 0 colors.primary.background=$remote_bg

  gpg-connect-agent updatestartuptty /bye;command ssh $argv
  set -l ssh_exit_status $status
  alacritty msg config -w 0 colors.primary.background=$default_bg
  return $ssh_exit_status
end
