#!/usr/bin/env bash

input=$(cat)

dir=$(jq -r '.workspace.current_dir // .cwd' <<< "$input")
model=$(jq -r '.model.display_name // empty' <<< "$input")
read -r tokens pct < <(jq -r '.context_window as $c | ($c.current_usage // {}) as $u
    | "\(($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) \($c.used_percentage // 0)"' <<< "$input")

location=${dir/#$HOME/\~}
branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null) \
    || branch=""
[ -z "$branch" ] && branch=$(git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
[ -n "$branch" ] && location="$location:$branch"

printf '%s · %s · %.1fK (%.0f%%)' "$location" "$model" "$(awk "BEGIN{print $tokens/1000}")" "$pct"
