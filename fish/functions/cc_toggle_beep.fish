function cc_toggle_beep --description "Toggle Claude Code beep notification"
    set -l flag ~/.claude/beep-enabled
    if test -f $flag
        rm $flag
        echo "Claude beep disabled"
    else
        touch $flag
        echo "Claude beep enabled"
    end
end
