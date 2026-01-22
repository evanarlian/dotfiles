if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -g fish_greeting
set -g fish_prompt_pwd_dir_length 3

fish_add_path "$HOME/bin"
fish_add_path "$HOME/.local/bin"


# Fish plugins
if functions -q fzf_configure_bindings
    # Search Directory   |  Ctrl+Alt+F (F for file)      |  --directory
    # Search Git Log     |  Ctrl+Alt+L (L for log)       |  --git_log
    # Search Git Status  |  Ctrl+Alt+S (S for status)    |  --git_status
    # Search History     |  Ctrl+R     (R for reverse)   |  --history
    # Search Processes   |  Ctrl+Alt+P (P for process)   |  --processes
    # Search Variables   |  Ctrl+Alt+E (E for variable)  |  --variables (changed becase 'v' is related to paste)
    fzf_configure_bindings --variables="ctrl-alt-e"
end

# brew
if type -q /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end

# uv
if type -q uv
    uv generate-shell-completion fish | source
end
if type -q uvx
    uvx --generate-shell-completion fish | source
end

# Added by `rbenv init` on Tue Jun 17 02:03:17 WIB 2025
if type -q rbenv
    status --is-interactive; and rbenv init - --no-rehash fish | source
end

if test (uname) = Darwin
    set -gx OBJC_DISABLE_INITIALIZE_FORK_SAFETY YES
end

# opencode
fish_add_path /home/evan/.opencode/bin

# mise
if type -q mise
    mise activate fish | source
end
