#!/usr/bin/env bash

# Only tested on GCP's "Deep Learning on Linux" boot disk image with Ubuntu.
#
# run from the internet:
# curl -fsSL https://raw.githubusercontent.com/evanarlian/dotfiles/main/vmprep/vmprep_gcp.sh | bash

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

echo "=== VM Prep (gcp) ==="

# Pre-accept GitHub SSH host key so git/ssh never prompts
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
sort -u -o ~/.ssh/known_hosts ~/.ssh/known_hosts

# Commit signing asks the forwarded SSH agent for its key at commit time
# (gpg.ssh.defaultKeyCommand in ~/.gitconfig below), so no key file is
# written here and whichever host is connected signs with its own key.
if ! ssh-add -L 2>/dev/null | grep -q ed25519; then
    echo "[warn] no ed25519 key in SSH agent, commit signing will not work. Run 'ssh-add' on the host and connect with agent forwarding."
fi

# Update apt cache once
if command -v apt-get &>/dev/null; then
    echo "[apt] updating package cache..."
    sudo apt-get update -qq
fi

# Core tools via apt
for pkg in build-essential tmux htop git tree curl wget jq unzip micro; do
    sudo_install_apt "$pkg"
done

# GitHub CLI
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian
if ! dpkg -s gh &>/dev/null; then
    (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update
    sudo apt-get install -y gh
else
    echo "[skip] gh already installed"
fi

# uv (Python package manager)
install_if_missing uv "curl -LsSf https://astral.sh/uv/install.sh | sh"

# Claude Code
install_if_missing claude "curl -fsSL https://claude.ai/install.sh | bash"

# mise — manages the node runtime
install_if_missing mise "curl https://mise.run | sh"

# Fresh installers drop binaries in ~/.local/bin; mise shims at
# ~/.local/share/mise/shims provide node/npm from the pinned runtime.
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Pin runtime versions
mise use -g node@24.13.1

# Language servers
# install_if_missing pyright "npm i -g pyright"

# Claude plugin marketplace (self-gating: no-op if already added)
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace update claude-plugins-official
# claude plugin install pyright-lsp

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

# NVIDIA Container Toolkit (GPU access inside Docker containers — skip if no GPU)
if command -v nvidia-smi &>/dev/null; then
    if dpkg -s nvidia-container-toolkit &>/dev/null; then
        echo "[skip] nvidia-container-toolkit already installed"
    else
        echo "[install] nvidia-container-toolkit..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
            | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
            | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
            | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y nvidia-container-toolkit
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
    fi
else
    echo "[skip] nvidia-container-toolkit (no GPU detected)"
fi

# === TMUX CONFIG ===
echo "[config] writing ~/.tmux.conf..."
cat > ~/.tmux.conf << 'TMUX_EOF'
# mouse mode to make tmux behaves more like regular app
set -g mouse on
setw -g mode-keys vi

# clipboard, two paths (both fire on every yank):
# 1. CLIP below: pipes into pbcopy (macOS) / wl-copy (wayland) / xclip (x11).
#    only works when tmux runs on the machine you're sitting at; on a headless
#    VM none of these exist, so it silently does nothing.
# 2. OSC 52: tmux sends the selection to the outer terminal as an escape
#    sequence, which travels back over ssh. this is what makes yank work from
#    a VM, but only in terminals that support it (VS Code yes; GNOME Terminal
#    and Terminal.app no).
# set-clipboard on (default is external) also lets programs inside tmux, like
# nvim or claude code, use OSC 52 to copy to your local clipboard.
set -s set-clipboard on
CLIP='if command -v pbcopy > /dev/null; then pbcopy; elif command -v wl-copy > /dev/null; then wl-copy; elif command -v xclip > /dev/null; then xclip -selection clipboard; fi'

# mouse drag just highlights + stays in copy-mode; it copies nothing (not even
# into tmux's paste buffer). only pressing y copies, to the clipboard.
unbind -T copy-mode-vi MouseDragEnd1Pane

# explicit yank: only y copies the selection to the system clipboard.
# Enter behaves like Escape: exits copy-mode without copying.
bind-key -T copy-mode-vi y     send-keys -X copy-pipe-and-cancel "$CLIP"
bind-key -T copy-mode-vi Enter send-keys -X cancel

# single Escape always exits copy-mode (default only clears the selection and
# stays, forcing a second Ctrl-C to actually leave).
bind-key -T copy-mode-vi Escape send-keys -X cancel

# larger buffer
set -g history-limit 100000

# enable color and true color
# advertise tmux's own terminfo to programs inside tmux (not "xterm", which is a lie)
set -g default-terminal "tmux-256color"
# let 24-bit true color pass through to the outer terminal
set -as terminal-features ",xterm-256color:RGB"

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
[gpg "ssh"]
	defaultKeyCommand = sh -c 'echo key::$(ssh-add -L | grep -m1 ed25519)'
GIT_EOF

# === BASH ALIASES & SSH AGENT FIX ===
echo "[config] adding bashrc snippets..."
if ! grep -q 'ssh-agent-socket-mgmt (managed by vmprep)' ~/.bashrc 2>/dev/null; then
cat >> ~/.bashrc << 'BASHRC_SSH'
# ssh-agent-socket-mgmt (managed by vmprep)
#
# Stable symlink at ~/.ssh/auth_sock for tmux panes and long-running procs
# that read $SSH_AUTH_SOCK once at startup. Every new shell always-replaces
# the link with its own raw sshd-forwarded sock — last-shell-wins, no
# liveness probing (too costly across a 250ms+ Pacific link). 'sshsock'
# is the manual re-rotate when the link target dies.

# Save raw before any rotation, so 'sshsock' can reach it later. Skip in
# panes whose env is already the link.
if [ -n "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/auth_sock" ]; then
    export __RAW_SSH_AUTH_SOCK="$SSH_AUTH_SOCK"
fi

# link -> raw
if [ -n "$__RAW_SSH_AUTH_SOCK" ] && [ -S "$__RAW_SSH_AUTH_SOCK" ]; then
    ln -sfn "$__RAW_SSH_AUTH_SOCK" "$HOME/.ssh/auth_sock"
fi
[ -L "$HOME/.ssh/auth_sock" ] && export SSH_AUTH_SOCK="$HOME/.ssh/auth_sock"

# Always-rotate, no liveness check. If $__RAW happens to be dead, the new
# link is dead too — that's a known limit. Inside tmux, $__RAW is usually
# the (dead) raw from when the pane was born, so we warn: the fix is to
# detach (Ctrl-b d), 'sshsock' in the outer shell, then 'tmux a'.
sshsock() {
    local raw="$__RAW_SSH_AUTH_SOCK"
    if [ -z "$raw" ]; then
        echo "sshsock: __RAW_SSH_AUTH_SOCK is unset" >&2
        return 1
    fi
    ln -sfn "$raw" "$HOME/.ssh/auth_sock"
    export SSH_AUTH_SOCK="$HOME/.ssh/auth_sock"
    echo "sshsock: link -> $raw"
    if [ -n "$TMUX" ]; then
        echo "         warning: inside tmux — \$__RAW may be stale from an old session." >&2
        echo "         if ssh-add still hangs: detach (Ctrl-b d), sshsock, tmux a." >&2
    fi
}
BASHRC_SSH
fi
if ! grep -q 'alias cc=' ~/.bashrc 2>/dev/null; then
    echo 'alias cc="claude --dangerously-skip-permissions"' >> ~/.bashrc
fi
if ! grep -q '\.local/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
if ! grep -q 'mise activate' ~/.bashrc 2>/dev/null; then
    echo 'eval "$(mise activate bash)"' >> ~/.bashrc
fi

echo ""
echo "=== VM Prep complete ==="
echo ""
echo ">>> TODO:"
echo ">>>   1) Try Claude:  claude"
echo ">>>   2) Login to GitHub CLI:  gh auth login -p ssh --skip-ssh-key -w"
echo ">>>   3) In VS Code, open the Extensions panel and click 'Install in SSH: <host>'"
echo ">>>   4) Log-out and log-in again to apply changes"
