if test (uname) = Darwin
    # TODO try on real mac
    bind alt-backspace backward-kill-word
    bind alt-\( kill-word
else
    # windows and linux
    bind ctrl-h backward-kill-word
    bind ctrl-delete kill-word
end
