function reload
    for f in ~/.config/fish/conf.d/*.fish
        source $f
    end
    source ~/.config/fish/config.fish
end
