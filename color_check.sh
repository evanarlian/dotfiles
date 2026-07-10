#!/usr/bin/env bash
# Stress test terminal color support: capability reports + visual eyeball tests.
# Run OUTSIDE tmux to check your raw terminal, then INSIDE tmux to check the
# tmux layer. Compare the two — they should look the same if config is correct.
set -Eeuo pipefail

section() { printf '\n\033[1m=== %s ===\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
section "What the environment claims"
# ---------------------------------------------------------------------------
printf 'TERM          = %s\n' "${TERM:-（unset）}"
printf 'COLORTERM     = %s   (want "truecolor" or "24bit" for true color)\n' "${COLORTERM:-（unset）}"
printf 'TERM_PROGRAM  = %s\n' "${TERM_PROGRAM:-（unset）}"
printf 'inside tmux?  = %s\n' "${TMUX:+yes}${TMUX:-no}"
printf 'terminfo colors (tput colors) = %s   (256 = 256-color palette)\n' "$(tput colors 2>/dev/null || echo '?')"

if [ -n "${TMUX:-}" ]; then
  section "What tmux thinks it supports (RGB/Tc = true color capable)"
  tmux info | grep -iE 'Tc|RGB' || echo 'no RGB/Tc capability found — true color likely OFF in tmux'
fi

# ---------------------------------------------------------------------------
section "16 basic ANSI colors (every terminal ever should pass this)"
# ---------------------------------------------------------------------------
for i in $(seq 0 15); do
  printf '\033[48;5;%sm  %3s  \033[0m' "$i" "$i"
  [ $(( (i + 1) % 8 )) -eq 0 ] && printf '\n'
done

# ---------------------------------------------------------------------------
section "256-color palette (should be a smooth grid, no gaps)"
# ---------------------------------------------------------------------------
for i in $(seq 16 231); do
  printf '\033[48;5;%sm  \033[0m' "$i"
  [ $(( (i - 15) % 36 )) -eq 0 ] && printf '\n'
done
printf '\n'
# grayscale ramp
for i in $(seq 232 255); do
  printf '\033[48;5;%sm  \033[0m' "$i"
done
printf '\n'

# ---------------------------------------------------------------------------
section "TRUE COLOR gradient (the real test)"
# ---------------------------------------------------------------------------
echo 'PASS = smooth continuous gradient.  FAIL = chunky bands / repeated blocks.'
awk 'BEGIN{
  for (i = 0; i < 76; i++) {
    r = 255 - (i * 255 / 76);
    g = (i * 510 / 76); if (g > 255) g = 510 - g;
    b = (i * 255 / 76);
    printf "\033[48;2;%d;%d;%dm ", r, g, b;
  }
  printf "\033[0m\n";
}'

# Strict single-channel ramp: the decisive test. Only blue varies 0->255.
# True color -> perfectly smooth. 256-color fallback -> ~6 visible blue bands
# (the 256-palette color cube has only 6 blue levels). This is what SSH into a
# host without the terminal-features RGB line looks like.
echo 'strict blue ramp (smooth = true color, ~6 bands = 256-color fallback):'
awk 'BEGIN{for(i=0;i<80;i++){b=int(i*255/79);printf "\033[48;2;0;0;%dm ",b}print "\033[0m"}'

# ---------------------------------------------------------------------------
section "Text attributes (bold / dim / italic / underline / reverse)"
# ---------------------------------------------------------------------------
printf '\033[1mbold\033[0m  \033[2mdim\033[0m  \033[3mitalic\033[0m  '
printf '\033[4munderline\033[0m  \033[7mreverse\033[0m  \033[9mstrikethrough\033[0m\n'

section "Done"
echo 'Tip: run this once outside tmux and once inside — they should match.'
