if status is-interactive
    # Commands to run in interactive sessions can go here
    fzf_configure_bindings --directory=\cf --processes=\cp --history=\cr --variables=\ce
end

source $__fish_config_dir/abbr.fish
source "$HOME/.cargo/env.fish"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/$USER/miniconda3/bin/conda
    eval /home/$USER/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/$USER/miniconda3/etc/fish/conf.d/conda.fish"
        . "/home/$USER/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/$USER/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

# Keybinding
bind \b backward-kill-word # enable ctrl backspace
bind \e\[3\;5~ kill-word # enable ctrl delete

# The next line updates PATH for the Google Cloud SDK.
if [ -f "/home/$USER/google-cloud-sdk/path.fish.inc" ]
    . "/home/$USER/google-cloud-sdk/path.fish.inc"
end

# starship must be at the very bottom to shadow all prompt modifiers
starship init fish | source
uv generate-shell-completion fish | source
uvx --generate-shell-completion fish | source
