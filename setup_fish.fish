#!/usr/bin/env fish

# Change default shell to fish
set fish_path (which fish)
echo "Changing default shell to: $fish_path"
sudo chsh -s $fish_path "$USER"
echo "Shell changed! Please restart your terminal."
echo ""

# Install fisher
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source

# Install fish plugins
set fish_plugins \
    jorgebucaran/fisher \
    jorgebucaran/hydro \
    patrickf1/fzf.fish \
    jethrokuan/z \
    evanarlian/python-module-fish-completion

for plugin in $fish_plugins
    fisher install $plugin
end
