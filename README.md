# dotfiles
The intention of this dotfile repo is not to automate the everything, but rather just to link the configs. Tested only on Ubuntu (`main` branch) and macOS (`macos` branch).

# usage
Clone and apply the config. Note that below step do not do any installation.
```bash
git clone -b main https://github.com/evanarlian/dotfiles.git  # ubuntu
git clone -b macos https://github.com/evanarlian/dotfiles.git  # macos
cd dotfiles
./link_config.sh
```

Optionally, change shell to fish and install extensions. Make sure fish is installed first.
```bash
./setup_fish.fish
```

# usage (broken for now)
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

# TODO:
* make main branch the core branch, and child branch: ubuntu, macos, ubuntu_vm, etc
* the mindset must be shifted, installation must come first, and then config population later
* make easily editable repo, such as last-minute config can be applied super fast by editing the repo
* change readme, one liner is great, but explanation is good.
