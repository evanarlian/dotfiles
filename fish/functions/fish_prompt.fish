function fish_prompt
        set -l last_status $status

        if test -n "$SSH_TTY"
                echo -n (set_color brred)"$USER"(set_color white)'@'(set_color yellow)(prompt_hostname)' '
        end

        echo -n (set_color blue)(prompt_pwd)' '

        set_color -o
        if fish_is_root_user
                echo -n (set_color red)'# '
        else if test $last_status -ne 0
                echo -n (set_color red)'❯ '
        else
                echo -n (set_color green)'❯ '
        end
        set_color normal
end
