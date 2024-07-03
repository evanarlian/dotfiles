#!/usr/bin/env bash

set -eu

install_essentials() {
    # setup git lfs repository
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo apt install -y \
        git git-lfs stow wget curl \
        grep jq tree \
        micro htop tmux \
        build-essential
    git lfs install
    # install fzf from release page because apt is outdated
    FZF_VER="fzf-0.49.0-linux_amd64.tar.gz"
    wget https://github.com/junegunn/fzf/releases/download/0.49.0/$FZF_VER
    mkdir -p $HOME/.local/bin/
    tar -xf $FZF_VER --directory=$HOME/.local/bin/
    rm $FZF_VER
}

install_fish() {
    # install newest version of fish directly from ppa
    sudo apt-add-repository ppa:fish-shell/release-3 -y
    sudo apt update
    sudo apt install fish -y
    # fisher and fish plugins
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
    # conda init is not really needed right now because we have user agnostic init commands in bash and fish
    # below changes will be replaced by stow anyway
    ~/miniconda3/bin/conda init bash fish
}

install_rust() {
    # rust toolchain
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # precompiled cargo binstall (for faster install)
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    # useful rust binaries
    ~/.cargo/bin/cargo binstall -y \
        bat fd-find just ripgrep tealdeer \
        starship
    tldr --update
}

stow_all() {
    # for vscode, we create the fake folder first to prevent stow to create symlink from so far above
    mkdir -p ~/.config/Code/User/
    # --adopt means taking existing file and overwriting files here (dotfiles repo)
    # --adopt followed by 'git restore .' is like saying: delete and use dotfiles only
    apps=(bash conda fish git rust starship tmux vscode)
    for app in "${apps[@]}"; do
        stow --adopt "$app"
    done
    git restore .
}

fish_clean_up() {
    fish -c 'set -U fish_greeting'
    fish -c 'fish_add_path -m ~/.local/bin/'
    fish -c 'fish_config theme choose "Base16 Eighties" && yes | fish_config theme save'
}

python_shortcut() {
    if [ -e /usr/bin/python3 ] && [ ! -e /usr/bin/python ]; then
        sudo ln -s /usr/bin/python3 /usr/bin/python
    fi
}

fix_nvidia_sleep() {
    sudo bash -c 'echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" > /etc/modprobe.d/nvidia-suspend.conf'
    for service in nvidia-suspend nvidia-hibernate nvidia-resume; do
        if systemctl list-unit-files | grep -q "$service"; then
            sudo systemctl enable "$service"
        fi
    done
}

install_cascadia_code_nerdfont() {
    mkdir -p /tmp/font
    cd /tmp/font
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip
    unzip CascadiaCode.zip
    sudo mkdir -p /usr/share/fonts/truetype/caskaydia
    sudo mv CaskaydiaCoveNerdFont* /usr/share/fonts/truetype/caskaydia
    cd -
    sudo rm -rf /tmp/font
}

install_essentials
install_fish
install_miniconda
install_rust
stow_all
fish_clean_up
python_shortcut
fix_nvidia_sleep
install_cascadia_code_nerdfont

echo "💫🍰🌸 Bootstrap finished!"
