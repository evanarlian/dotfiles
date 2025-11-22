if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -g fish_greeting
set -g fish_prompt_pwd_dir_length 3

fish_add_path "$HOME/bin"
fish_add_path "$HOME/.local/bin"


# Fish plugins
if functions -q fzf_configure_bindings
    fzf_configure_bindings --directory="ctrl-f" --processes="ctrl-p" --history="ctrl-r" --variables="ctrl-e"
end

# uv
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

# Added by `rbenv init` on Tue Jun 17 02:03:17 WIB 2025
if type -q rbenv
    status --is-interactive; and rbenv init - --no-rehash fish | source
end

if test (uname) = Darwin
    set -gx OBJC_DISABLE_INITIALIZE_FORK_SAFETY YES
end

# Added by Antigravity
fish_add_path "$HOME/antigravity/antigravity/bin"
