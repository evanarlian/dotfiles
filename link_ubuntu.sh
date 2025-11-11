#!/usr/bin/env bash
set -Eeuo pipefail

link_file() {
    local source="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ]; then
        rm "$target"
    elif [ -e "$target" ]; then
        echo "⚠️  $target exists, backing up to ${target}.backup"
        mv "$target" "${target}.backup"
    fi
    ln -s "$source" "$target"
    echo "✓ $target"
}

echo "🔗 Linking dotfiles..."

# Single files
link_file "$(pwd)/.gitconfig" "$HOME/.gitconfig"
link_file "$(pwd)/.gitconfig-work" "$HOME/.gitconfig-work"
link_file "$(pwd)/.tmux.conf" "$HOME/.tmux.conf"
link_file "$(pwd)/.condarc" "$HOME/.condarc"
link_file "$(pwd)/starship.toml" "$HOME/.config/starship.toml"

# Fish
link_file "$(pwd)/fish/.config/fish" "$HOME/.config/fish"

# VSCode
link_file "$(pwd)/vscode/Code/User/settings.json" "$HOME/.config/Code/User/settings.json"
link_file "$(pwd)/vscode/Code/User/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
link_file "$(pwd)/vscode/Code/User/snippets" "$HOME/.config/Code/User/snippets"

echo "✨ Done!"
