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

Optionally, change shell to fish and install extensions. Make sure fish is installed first.
```bash
./setup_fish.fish
```
