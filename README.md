# dotfiles
The intention of this dotfile repo is not to automate everything, but rather just to link the configs. Tested on Ubuntu (`main` branch) and macOS (`macos` branch).

# usage
Clone and apply the config. Note that below steps do not do any installation.
```bash
git clone -b main https://github.com/evanarlian/dotfiles.git  # ubuntu
git clone -b macos https://github.com/evanarlian/dotfiles.git  # macos
cd dotfiles
./link_config.sh
```

Optional
```bash
./setup_fish.fish  # install fish ext
./install_font.sh  # install fonts
```

# development
If needed, review before merging between branches and merge manually.
```bash
git pull origin main --no-ff --no-commit
```
