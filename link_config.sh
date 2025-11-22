#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_file() {
    local source="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ]; then
        rm "$target"
    elif [ -e "$target" ]; then
        echo "⚠️  $target exists, backing up to ${source}.backup"
        mv "$target" "${source}.backup"
    fi
    ln -s "$source" "$target"
    echo "✓ $target"
}

echo "📦 Detected OS: $OSTYPE"
echo "🔗 Linking dotfiles from $DOTFILES_DIR"

link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.gitconfig_work" "$HOME/.gitconfig_work"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.condarc" "$HOME/.condarc"
link_file "$DOTFILES_DIR/fish" "$HOME/.config/fish"

if [[ "$OSTYPE" == "darwin"* ]]; then
    link_file "$DOTFILES_DIR/vscode/Code/User/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    link_file "$DOTFILES_DIR/vscode/Code/User/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
    link_file "$DOTFILES_DIR/vscode/Code/User/snippets" "$HOME/Library/Application Support/Code/User/snippets"
else
    link_file "$DOTFILES_DIR/vscode/Code/User/settings.json" "$HOME/.config/Code/User/settings.json"
    link_file "$DOTFILES_DIR/vscode/Code/User/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
    link_file "$DOTFILES_DIR/vscode/Code/User/snippets" "$HOME/.config/Code/User/snippets"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    link_file "$DOTFILES_DIR/.hammerspoon" "$HOME/.hammerspoon"
fi


echo "✨ Done!"
