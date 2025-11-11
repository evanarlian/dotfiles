#!/usr/bin/env bash
set -Eeuo pipefail

# Get the directory where this script lives (the dotfiles repo)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔗 Linking dotfiles from: $DOTFILES_DIR"

link_file() {
    local source="$1"
    local target="$2"

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target")"

    # Remove existing symlink or file
    if [ -L "$target" ]; then
        rm "$target"
    elif [ -e "$target" ]; then
        echo "⚠️  Warning: $target exists and is not a symlink. Backing up to ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    # Create the symlink
    ln -s "$source" "$target"
    echo "✓ Linked: $target -> $source"
}

# Git configs
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.gitconfig-work" "$HOME/.gitconfig-work"

# Tmux
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Conda
link_file "$DOTFILES_DIR/.condarc" "$HOME/.condarc"

# Starship
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# Fish - link the inner .config/fish directory
link_file "$DOTFILES_DIR/fish/.config/fish" "$HOME/.config/fish"

# VSCode
VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
link_file "$DOTFILES_DIR/vscode/Code/User/settings.json" "$VSCODE_CONFIG_DIR/settings.json"
link_file "$DOTFILES_DIR/vscode/Code/User/keybindings.json" "$VSCODE_CONFIG_DIR/keybindings.json"
link_file "$DOTFILES_DIR/vscode/Code/User/snippets" "$VSCODE_CONFIG_DIR/snippets"

echo ""
echo "✨ All dotfiles linked successfully!"
