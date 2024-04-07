# Quickstart
Run and wait.
```bash
git clone https://github.com/evanarlian/dotfiles.git && cd dotfiles && sudo apt update && ./install.sh
```
Optionally, change shell to fish.
```bash
sudo chsh -s /usr/bin/fish "$USER"
```
Restart your terminal.

# Usage
Using `stow` to put symlinks to another places. `--adopt` can be used to resolve conflicts by copying existing content and creating a symlink in its place.
```bash
stow bash  
stow --adopt bash
```
There is sanity check to confirm everything installed by `install.sh` are working properly. Run this after terminal restarts (to allow PATHs, etc to be fully added).
```bash
./sanity_check.sh
```
This sanity check uses tmux under the hood. You can inspect the result by running
```bash
tmux a -t _sanity_check
```
# Guidelines
* Periodically watch for new files in a directory (for example a new vscode snippets), because they are not tracked yet.
