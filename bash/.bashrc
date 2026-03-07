# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
# Make an alias for invoking commands you use constantly
alias shx='sudo helix'
alias hx='helix'
alias p='python'

# Set a custom prompt with the directory revealed (alternatively use https://starship.rs)
# PS1="\W \[\e]0;\w\a\]$PS1"

# opencode
export PATH=/home/dn/.opencode/bin:$PATH

. "$HOME/.local/share/../bin/env"
