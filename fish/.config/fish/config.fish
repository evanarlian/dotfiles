if status is-interactive
    # Commands to run in interactive sessions can go here
    fzf_configure_bindings --directory=\cf --processes=\cp --history=\cr --variables=\ce
end

source $__fish_config_dir/abbr.fish
source "$HOME/.cargo/env.fish"
starship init fish | source

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
eval /home/evan/miniconda3/bin/conda "shell.fish" hook $argv | source
# <<< conda initialize <<<

# Keybinding
bind \b backward-kill-word # enable ctrl backspace
bind \e\[3\;5~ kill-word # enable ctrl delete

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/evan/google-cloud-sdk/path.fish.inc' ]
    . '/home/evan/google-cloud-sdk/path.fish.inc'
end
