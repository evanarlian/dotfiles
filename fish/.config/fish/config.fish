if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -g fish_greeting

if test -f "$__fish_config_dir/abbr.fish"
    source "$__fish_config_dir/abbr.fish"
end
if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end
fish_add_path "$HOME/bin"
fish_add_path "$HOME/.local/bin"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/$USER/miniconda3/bin/conda
    eval /home/$USER/miniconda3/bin/conda "shell.fish" hook $argv | source
else
    if test -f "/home/$USER/miniconda3/etc/fish/conf.d/conda.fish"
        . "/home/$USER/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/$USER/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

# Keybindings
bind ctrl-h backward-kill-word # enable ctrl backspace
bind ctrl-delete kill-word

# Fish plugins
if functions -q fzf_configure_bindings
    fzf_configure_bindings --directory="ctrl-f" --processes="ctrl-p" --history="ctrl-r" --variables="ctrl-e"
end
if [ -f "/home/$USER/google-cloud-sdk/path.fish.inc" ]
    . "/home/$USER/google-cloud-sdk/path.fish.inc"
end

if type -q uv
    uv generate-shell-completion fish | source
end
if type -q uvx
    uvx --generate-shell-completion fish | source
end

# starship must be at the very bottom to shadow all prompt modifiers
if type -q starship
    starship init fish | source
end
