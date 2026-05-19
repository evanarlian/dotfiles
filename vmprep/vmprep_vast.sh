#!/usr/bin/env bash

# Only tested on vast.ai's "NVIDIA CUDA" docker image template.
#
# run from the internet:
# curl -fsSL https://raw.githubusercontent.com/evanarlian/dotfiles/macos/vmprep/vmprep_vast.sh | bash

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

echo "=== VM Prep (vast.ai) ==="

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
        echo "[warn] no ed25519 key found in SSH agent, commit signing will not work. Run `ssh-add` from host first to add ssh key."
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
for pkg in build-essential tmux htop git tree curl wget jq unzip qpdf; do
    sudo_install_apt "$pkg"
done

# nvtop (GPU monitoring — skip if no GPU)
if command -v nvidia-smi &>/dev/null; then
    sudo_install_apt nvtop
else
    echo "[skip] nvtop (no GPU detected)"
fi

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

# Google Cloud CLI (gcloud, gsutil, bq)
# https://cloud.google.com/sdk/docs/install#deb
if ! dpkg -s google-cloud-cli &>/dev/null; then
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y google-cloud-cli
else
    echo "[skip] google-cloud-cli already installed"
fi

# uv (Python package manager)
install_if_missing uv "curl -LsSf https://astral.sh/uv/install.sh | sh"

# Claude Code
install_if_missing claude "curl -fsSL https://claude.ai/install.sh | bash"

# mise — manages node, ruby, go runtimes
install_if_missing mise "curl https://mise.run | sh"

# Fresh installers drop binaries in ~/.local/bin; mise shims at
# ~/.local/share/mise/shims provide npm/go/gem from the pinned runtimes.
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Precompiled Ruby — default compile-from-source needs gcc + libssl-dev etc.
mise settings ruby.compile=false

# Pin company runtime versions
mise use -g node@24.13.1 ruby@3.3.6 go@1.25.0

# Language servers
install_if_missing pyright "npm i -g pyright"
install_if_missing typescript-language-server "npm i -g typescript-language-server typescript"
install_if_missing gopls "go install golang.org/x/tools/gopls@latest"
install_if_missing ruby-lsp "gem install ruby-lsp"

# Claude plugin marketplace (self-gating: no-op if already added)
claude plugin marketplace add getboon/boon-plugins
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace update claude-plugins-official
claude plugin install pyright-lsp
claude plugin install typescript-lsp
claude plugin install gopls-lsp
claude plugin install ruby-lsp

# === VAST.AI CONFIG ===
# Disable vast.ai's auto-tmux which breaks SSH agent forwarding
touch ~/.no_auto_tmux
# Remove vast.ai's auto venv activation from bashrc
sed -i '/\/venv\/.*\/bin\/activate/d' ~/.bashrc
# Remove vast.ai's forced cd to /workspace
sed -i '/^cd ${WORKSPACE}/d' ~/.bashrc
# sshd inherits stale PWD=/workspace from the container entrypoint; resync it
if ! grep -q 'PWD=.*pwd' ~/.bashrc 2>/dev/null; then
    echo 'export PWD="$(/bin/pwd -P)"' >> ~/.bashrc
fi

# === CONDARC ===
# Disable conda auto-activate base (vast.ai images often have conda pre-installed)
echo "[config] writing ~/.condarc..."
cat > ~/.condarc << 'CONDARC_EOF'
auto_activate_base: false
CONDARC_EOF

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

# === BASH ALIASES & SSH AGENT FIX ===
echo "[config] adding bashrc snippets..."
# Stable symlink for SSH agent so old tmux panes survive reattach AND
# self-heal across SSH reconnects (including VS Code Remote-SSH, which
# adds a wrapper socket layer).
# Use BEGIN/END markers so we can re-install idempotently.
SSH_SOCK_BEGIN='# >>> ssh-agent-socket-mgmt (managed by vmprep) >>>'
SSH_SOCK_END='# <<< ssh-agent-socket-mgmt (managed by vmprep) <<<'

# Strip any previous version of the block (old or new) before re-appending.
if grep -qF "$SSH_SOCK_BEGIN" ~/.bashrc 2>/dev/null; then
    sed -i "\|$SSH_SOCK_BEGIN|,\|$SSH_SOCK_END|d" ~/.bashrc
fi
# Also strip the legacy unmarked snippet from an older vmprep run.
if grep -q 'ssh/auth_sock' ~/.bashrc 2>/dev/null; then
    sed -i '/# Keep a stable symlink so tmux panes survive SSH reattach/,/^fi$/d' ~/.bashrc
fi

cat >> ~/.bashrc << BASHRC_SSH
$SSH_SOCK_BEGIN
# Stable symlink so tmux panes survive SSH reconnect, and concurrent SSH
# sessions don't poison each other when one dies first. Re-checks liveness
# on every prompt: [ -S ] alone is not enough — orphaned /tmp/ssh-*/agent.N
# linger as socket files after their sshd dies, and VS Code's
# --enable-remote-auto-shutdown keeps an sshd alive past its real disconnect
# with a half-dead agent socket. Both pass [ -S ], both hang ssh-add. Hence
# the explicit probe.
__sock_is_live() {
    local s="\$1"
    local pid="\${s##*.}"
    # PID prefilter: /tmp/ssh-XXX/agent.NNNN's NNNN is the sshd child PID.
    # Gone or comm != sshd ⇒ socket dead. ~50us, no fork. Non-PID-named
    # candidates (e.g. vscode wrappers) skip this and probe directly.
    case "\$pid" in
        ''|*[!0-9]*) ;;
        *)
            [ -d "/proc/\$pid" ] || return 1
            [ "\$(< /proc/\$pid/comm 2>/dev/null)" = sshd ] || return 1
            ;;
    esac
    # Definitive probe. ~5ms typical; ~200ms on timeout in the zombie case.
    SSH_AUTH_SOCK="\$s" timeout 0.2 ssh-add -l >/dev/null 2>&1
    case \$? in 0|1) return 0;; *) return 1;; esac
}

__refresh_ssh_auth_sock() {
    local link="\$HOME/.ssh/auth_sock"

    # Fast path: link is sticky while live. A new session arriving while
    # the link works keeps using it, so transient sessions can't hijack it.
    if [ -S "\$link" ] && __sock_is_live "\$link"; then
        export SSH_AUTH_SOCK="\$link"
        return 0
    fi

    # Slow path: link is bad. This shell may have a fresh raw socket in
    # its env from sshd/VS Code — adopt it if it actually responds.
    if [ -n "\$SSH_AUTH_SOCK" ] \\
        && [ "\$SSH_AUTH_SOCK" != "\$link" ] \\
        && [ -S "\$SSH_AUTH_SOCK" ] \\
        && __sock_is_live "\$SSH_AUTH_SOCK"; then
        ln -sfn "\$SSH_AUTH_SOCK" "\$link"
        export SSH_AUTH_SOCK="\$link"
        return 0
    fi

    # Last resort: scan /tmp for the newest live socket owned by this user.
    # Prefer vscode wrappers (that's what vscode terminals were handed),
    # then plain sshd-forwarded sockets. __sock_is_live skips dead ones.
    local s
    for s in \$(ls -1t /tmp/vscode-ssh-auth-sock-* /tmp/ssh-*/agent.* 2>/dev/null); do
        if [ -S "\$s" ] && [ -O "\$s" ] && __sock_is_live "\$s"; then
            ln -sfn "\$s" "\$link"
            export SSH_AUTH_SOCK="\$link"
            return 0
        fi
    done

    # Nothing live found — point at the link anyway so future heals are seen.
    export SSH_AUTH_SOCK="\$link"
    return 1
}

__refresh_ssh_auth_sock

# Run on every prompt so existing tmux panes notice when another session
# brings a live socket online. Idempotent — \$PROMPT_COMMAND is only
# augmented if our hook isn't already in it.
case "\$PROMPT_COMMAND" in
    *__refresh_ssh_auth_sock*) ;;
    *) PROMPT_COMMAND="__refresh_ssh_auth_sock\${PROMPT_COMMAND:+; \$PROMPT_COMMAND}" ;;
esac
$SSH_SOCK_END
BASHRC_SSH
if ! grep -q 'alias cc=' ~/.bashrc 2>/dev/null; then
    # auto mode instead of --dangerously-skip-permissions because the latter is blocked as root
    echo 'alias cc="claude --permission-mode auto"' >> ~/.bashrc
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
echo ">>>   1) Login to Claude:  claude  (open with VS Code terminal for browser auto-open)"
echo ">>>   2) Login to GitHub:  gh auth login"
echo ">>>   3) Login to GCP:     gcloud auth login"
echo ">>>   4) In VS Code, open the Extensions panel and click 'Install in SSH: <host>'"
echo ">>>   5) Log-out and log-in again to apply changes"
