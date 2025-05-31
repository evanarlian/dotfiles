# quickstart
Run and wait. Only tested on Ubuntu 22.04. **Warning:** will overwrite without confirmation.
```bash
git clone https://github.com/evanarlian/dotfiles.git && cd dotfiles && sudo apt update && ./install.sh
```
Optionally, change shell to fish.
```bash
sudo chsh -s /usr/bin/fish "$USER"
```
Restart your terminal. After changing shell, tmux might still use the old default. Restart solves this.

# usage
Using `stow` to put symlinks to another places. `--adopt` can be used to resolve conflicts by copying existing content and creating a symlink in its place.
```bash
stow bash  
stow --adopt bash
```
There is sanity check to confirm everything installed by `install.sh` are working properly. Run this **after** terminal restarts (to allow PATHs, etc to be fully added).
```bash
./sanity_check.sh
```
This sanity check uses tmux under the hood. You can inspect the result by running
```bash
tmux a -t _sanity_check
tmux kill-session -t _sanity_check  # after done looking
```

# guidelines
* TODO: recheck **fish** again in the future because 4.0.2 tab cycle is broken on vscode, while nightly is not
* Some things need to be periodically updated:
    * fzf (just bump the version from latest in github)
    * CaskaydiaMonoNerdFont (mono is ligature-free)
    * tilix.dconf (to update: `dconf dump /com/gexperts/Tilix/ > tilix/tilix.dconf`)
