function fish_prompt
    set -l last_status $status

    # explicit ssh info
    if test -n "$SSH_TTY"
        echo -n (set_color brred)"$USER"(set_color white)'@'(set_color yellow)(prompt_hostname)' '
    end

    # pwd, chunk length variable setting: fish_prompt_pwd_dir_length
    echo -n (set_color brblue)(prompt_pwd)' '

    # > symbol
    if test $last_status -eq 0
        if test -n "$fish_private_mode"
            echo -n (set_color -or brgreen)'❯'
        else
            echo -n (set_color -o brgreen)'❯'
        end
    else
        if test -n "$fish_private_mode"
            echo -n (set_color -or brred)'❯'
        else
            echo -n (set_color -o brred)'❯'
        end
    end
    set_color normal
    echo -n ' '
end
