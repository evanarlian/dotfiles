#!/usr/bin/env bash

[ -f ~/.claude/beep-enabled ] || exit 0

case "$(uname -s)" in
    Darwin)
        afplay /System/Library/Sounds/Glass.aiff
        ;;
    Linux)
        if command -v paplay &>/dev/null; then
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null
        elif command -v aplay &>/dev/null; then
            aplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null
        fi
        ;;
esac
