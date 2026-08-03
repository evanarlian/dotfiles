function clear
    command clear $argv
    # macos clear ignores the E3 capability, so wipe scrollback ourselves.
    # linux clear already handles this, leave it alone.
    if test (uname) = Darwin
        printf '\e[3J'
    end
end
