#!/usr/bin/env bash

set -eu

SESS="_sanity_check"

function test_essentials() {
    WIN="essn"
    tmux new-window -t $SESS -n $WIN
    tmux splitp -v -t $SESS:$WIN.1
    tmux splitp -h -t $SESS:$WIN.1
    tmux splitp -h -t $SESS:$WIN.3
    tmux send -t $SESS:$WIN.1 "htop" enter
    tmux send -t $SESS:$WIN.2 "micro sanity_check.sh" enter
    tmux send -t $SESS:$WIN.3 "fzf" enter
    tmux send -t $SESS:$WIN.4 "tree -aLF 2" enter
    tmux send -t $SESS:$WIN.4 "echo '{\"code\": \"dQw4w9WgXcQ\"}' | jq" enter
}

function test_fish() {
    WIN="fish_"  # prevent overlap with preexisting window called "fish"
    tmux new-window -t $SESS -n $WIN
    tmux send -t $SESS:$WIN "fish" enter
    tmux send -t $SESS:$WIN "fisher list" enter
    tmux send -t $SESS:$WIN "_fzf_search_history" enter
}

function test_miniconda() {
    WIN="conda"
    tmux new-window -t $SESS -n $WIN
    tmux splitp -v -t $SESS:$WIN.1
    tmux send -t $SESS:$WIN.1 "bash" enter
    tmux send -t $SESS:$WIN.1 "ca base" enter
    tmux send -t $SESS:$WIN.1 "conda env list" enter
    tmux send -t $SESS:$WIN.2 "fish" enter
    tmux send -t $SESS:$WIN.2 "ca base" enter
    tmux send -t $SESS:$WIN.2 "conda env list" enter
}

function test_rust() {
    WIN="rust"
    tmux new-window -t $SESS -n $WIN
    tmux send -t $SESS:$WIN "cargo" enter
    tmux send -t $SESS:$WIN "bat --paging=never README.md" enter
    tmux send -t $SESS:$WIN "fd -e sh" enter
    tmux send -t $SESS:$WIN "just -V" enter
    tmux send -t $SESS:$WIN "rg stow" enter
}


if tmux has-session -t $SESS 2>/dev/null; then
    echo "tmux session $SESS exists, kill first to run sanity check again."
    exit
fi

tmux new -d -s $SESS
test_essentials
test_fish
test_miniconda
test_rust
tmux kill-window -t $SESS:1  # remove first window created implicitly by tmux new
tmux select-window -t $SESS:1  # go to first window for aesthetics
