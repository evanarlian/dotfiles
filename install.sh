#!/usr/bin/env bash
set -Eeuxo pipefail

install_essentials() {
    # setup git lfs repository
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo apt install -y \
        software-properties-common \
        git git-lfs stow wget curl \
        grep jq tree \
        micro htop tmux \
        build-essential
    git lfs install
    # install fzf from release page because apt is outdated
    wget https://github.com/junegunn/fzf/releases/download/v0.57.0/fzf-0.57.0-linux_amd64.tar.gz -O fzf.tar.gz
    mkdir -p $HOME/.local/bin/
    tar -xf fzf.tar.gz --directory=$HOME/.local/bin/ 
    rm fzf.tar.gz
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
        evanarlian/python-module-fish-completion
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
    ~/.cargo/bin/tldr --update
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

install_python_tooling() {
    # install uv and uvx
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # TODO add uv tools, there are a lot of nice python tools
    # eg httpie, ruff, glance, etc
}

fix_nvidia_sleep() {
    sudo bash -c 'echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" > /etc/modprobe.d/nvidia-suspend.conf'
    for service in nvidia-suspend nvidia-hibernate nvidia-resume; do
        if systemctl list-unit-files | grep -q "$service"; then
            sudo systemctl enable "$service"
        fi
    done
}

install_cascadia_mono_nerdfont() {
    mkdir -p /tmp/font
    cd /tmp/font
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaMono.zip
    unzip CascadiaMono.zip
    sudo mkdir -p /usr/share/fonts/truetype/caskaydia
    sudo mv CaskaydiaMonoNerdFont* /usr/share/fonts/truetype/caskaydia
    cd -
    sudo rm -rf /tmp/font
}

append_cuda_ld_libraries() {
    # I don't want to use LD_LIBRARY_PATH because the behavior is prepend, can mess with preinstalled libraries
    # write to temp file first to capture the script executor's name
    tempfile=$(mktemp)
    cat << EOF > $tempfile
/home/$USER/miniconda3/envs/cuda11/lib
/home/$USER/miniconda3/envs/cuda12/lib
/home/$USER/miniconda3/envs/cudnn8/lib
/home/$USER/miniconda3/envs/cudnn9/lib
EOF
    sudo mv $tempfile /etc/ld.so.conf.d/zzz_conda_cuda_ld_lib.conf
    sudo ldconfig  # rebuild dynamic linker cache
    fish -c "set -Ux CUDA_HOME /home/$USER/miniconda3/envs/cuda12"  # some python libs require this, e.g. deepspeed
}


install_essentials
install_fish
install_miniconda
install_rust
stow_all
fish_clean_up
python_shortcut
install_python_tooling
fix_nvidia_sleep
install_cascadia_mono_nerdfont
append_cuda_ld_libraries

echo "💫🍰🌸 Bootstrap finished!"
