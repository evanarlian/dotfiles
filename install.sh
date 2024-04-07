#!/usr/bin/env bash

install_essentials() {
    sudo apt install -y \
        git stow wget curl \
        grep fzf jq tree \
        micro htop tmux \
        build-essential
}

install_fish() {
    sudo apt install fish -y
    fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
    fish_plugins=(
        jorgebucaran/fisher
        patrickf1/fzf.fish
        jorgebucaran/nvm.fish
        evanarlian/google-cloud-sdk-fish-completion
        jethrokuan/z
    )
    for plugin in "${fish_plugins[@]}"; do
        fish -c "fisher install $plugin"
    done
}

install_miniconda() {
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm -rf ~/miniconda3/miniconda.sh
    # conda init is done later after stow to ensure correct user name (for path)
}

install_rust() {
    # rust toolchain
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # precompiled cargo binstall (for faster install)
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    # useful rust binaries
    ~/.cargo/bin/cargo binstall -y \
        bat fd-find just ripgrep \
        starship
}

stow_all() {
    # --adopt means taking existing file and overwriting files here (dotfiles repo)
    # --adopt followed by 'git restore .' is like saying: delete and use dotfiles only
    apps=(bash conda fish git rust starship tmux vscode)
    for app in "${apps[@]}"; do
        stow --adopt "$app"
    done
    git restore .
}

clean_up() {
    ~/miniconda3/bin/conda init bash fish
}

install_essentials
install_fish
install_miniconda
install_rust
stow_all
clean_up
