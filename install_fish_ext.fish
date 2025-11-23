#!/usr/bin/env fish

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
