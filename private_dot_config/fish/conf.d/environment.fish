# note: more env-vars are defined in other `conf.d/*` fish configuration files. use `printenv` or the fish `set -S` command to see all vars.
set -gx CHEZMOI_SOURCE_DIR "$HOME/.local/share/chezmoi" # otherwise set only after chezmoi cd, needed for devpods
set -gx RIPGREP_CONFIG_PATH "$XDG_CONFIG_HOME/ripgrep/config"
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx SHELL "fish"
set -gx TERMINAL "alacritty"
set -gx EDITOR "nvim"
set -gx DIFFPROG "nvim -d"
set -gx BROWSER "brave-browser"
# remember: an awesome feature of `nvim +Man!` is `gO` (gee-Oh) to open an browsable index of the manpage in the quickfix list
# set -gx PAGER "nvim +Man!"
set -gx PAGER "less"
set -gx LANG "en_US.UTF-8"
