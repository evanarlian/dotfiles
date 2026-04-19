#!/usr/bin/env bash

# run from the internet:
# curl -fsSL https://raw.githubusercontent.com/evanarlian/dotfiles/macos/vmprep.sh | bash

set -euo pipefail

install_if_missing() {
    local cmd="$1"
    local install_fn="$2"
    if command -v "$cmd" &>/dev/null; then
        echo "[skip] $cmd already installed"
    else
        echo "[install] $cmd..."
        eval "$install_fn"
    fi
}

# System packages (apt-based, typical for DL VMs)
sudo_install_apt() {
    local pkg="$1"
    if dpkg -s "$pkg" &>/dev/null; then
        echo "[skip] $pkg already installed"
    else
        echo "[install] $pkg..."
        sudo apt-get install -y "$pkg"
    fi
}

echo "=== VM Prep ==="

# Pre-accept GitHub SSH host key so git/ssh never prompts
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
sort -u -o ~/.ssh/known_hosts ~/.ssh/known_hosts

# Extract ed25519 public key from SSH agent for commit signing.
# With agent forwarding the private key never touches the VM, but
# git's SSH signing still needs the .pub file on disk.
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
    if ssh-add -L | grep -m1 ed25519 > ~/.ssh/id_ed25519.pub 2>/dev/null; then
        echo "[config] wrote ~/.ssh/id_ed25519.pub from SSH agent"
    else
        rm -f ~/.ssh/id_ed25519.pub
        echo "[warn] no ed25519 key found in SSH agent — commit signing will not work"
    fi
else
    echo "[skip] ~/.ssh/id_ed25519.pub already exists"
fi

# Update apt cache once
if command -v apt-get &>/dev/null; then
    echo "[apt] updating package cache..."
    sudo apt-get update -qq
fi

# Core tools via apt
for pkg in make tmux htop git tree curl wget jq unzip; do
    sudo_install_apt "$pkg"
done

# nvtop (GPU monitoring)
sudo_install_apt nvtop

# GitHub CLI
install_if_missing gh "(curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt-get update -qq && sudo apt-get install -y gh)"

# uv (Python package manager)
install_if_missing uv "curl -LsSf https://astral.sh/uv/install.sh | sh"

# Claude Code
install_if_missing claude "curl -fsSL https://claude.ai/install.sh | bash"

# Fresh installers drop binaries in ~/.local/bin and update ~/.bashrc, but that
# PATH change doesn't apply to the currently-running script — add it explicitly.
export PATH="$HOME/.local/bin:$PATH"

# Claude plugin marketplace (self-gating: no-op if already added)
claude plugin marketplace add getboon/boon-plugins

# Docker (official convenience script)
install_if_missing docker "curl -fsSL https://get.docker.com | sh"

# Add current user to docker group so `docker` works without sudo.
# Check /etc/group (persistent state), not `id` (shell-snapshot state) —
# otherwise a prior run that happened in this same shell looks "missing".
if ! getent group docker | grep -qw "$USER"; then
    echo "[config] adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
else
    echo "[skip] $USER already in docker group"
fi

# NVIDIA Container Toolkit (GPU access inside Docker containers)
if dpkg -s nvidia-container-toolkit &>/dev/null; then
    echo "[skip] nvidia-container-toolkit already installed"
else
    echo "[install] nvidia-container-toolkit..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
        | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
fi

# === TMUX CONFIG ===
echo "[config] writing ~/.tmux.conf..."
cat > ~/.tmux.conf << 'TMUX_EOF'
# FAQ: https://github.com/tmux/tmux/wiki/FAQ

# mouse mode to make tmux behaves more like regular app
set -g mouse on
setw -g mode-keys vi
unbind -T copy-mode-vi MouseDragEnd1Pane
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "if command -v pbcopy > /dev/null; then pbcopy; elif command -v wl-copy > /dev/null; then wl-copy; elif command -v xclip > /dev/null; then xclip -selection clipboard; fi"

# enable color and true color
set -g default-terminal "xterm-256color"
set -ag terminal-overrides ",xterm*:RGB"

# start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1

# windows: (1 2 3 4), if you delete (2), (3 4) will become (2 3)
set -g renumber-windows on

# new window from current dir in the pane
bind c new-window -c "#{pane_current_path}"

# split pane from current dir in the pane, not from when tmux session created
unbind '"'
unbind %
bind - split-window -v -c "#{pane_current_path}"
bind \\ split-window -h -c "#{pane_current_path}"

# toggle readonly or not using L key
unbind l
bind-key l run-shell 'if [ #{pane_input_off} = "1" ]; then tmux select-pane -e; else tmux select-pane -d; fi'

# toggle synchronize panes (type on all panes simultaneously)
unbind s
bind-key s setw synchronize-panes

# status bar
set -g status-right '#{?pane_input_off,LOCKED ,}#{?synchronize-panes,SYNC ,} %H:%M %d-%b-%y'

# reload source
bind r source-file ~/.tmux.conf
TMUX_EOF

# === GITCONFIG ===
echo "[config] writing ~/.gitconfig..."
cat > ~/.gitconfig << 'GIT_EOF'
[user]
	name = Evan Arlian
	email = evan.arlian@getboon.ai
	signingkey = ~/.ssh/id_ed25519.pub
[push]
	autoSetupRemote = true
[pull]
	rebase = false
[credential]
	helper = store
[commit]
	gpgsign = true
[gpg]
	format = ssh
GIT_EOF

# === BASH ALIASES ===
echo "[config] adding cc alias to ~/.bashrc..."
if ! grep -q 'alias cc=' ~/.bashrc 2>/dev/null; then
    echo 'alias cc="claude --dangerously-skip-permissions"' >> ~/.bashrc
fi

echo ""
echo "=== VM Prep complete ==="
echo ""
echo ">>> TODO:"
echo ">>>   1) Login to Claude:   claude"
echo ">>>   2) Login to GitHub:   gh auth login"
echo ">>>   3) In VS Code, open the Extensions panel and click 'Install in SSH: <host>'"
echo ">>>   4) Log-out and log-in again to apply changes"
