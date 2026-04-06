#!/usr/bin/env bash
# Claude Code Status Line — custom styled status bar
# https://github.com/Bonny07/pawline
#
# Usage: Add to ~/.claude/settings.json:
#   "statusLine": {
#     "type": "command",
#     "command": "bash ~/.claude/statusline.sh"
#   }

input=$(cat)

# --- Colors (RGB true color) ---
C_BLUE="\033[38;2;0;153;255m"
C_CYAN="\033[38;2;86;182;194m"
C_GREEN="\033[38;2;0;175;80m"
C_ORANGE="\033[38;2;255;176;85m"
C_YELLOW="\033[38;2;230;200;0m"
C_RED="\033[38;2;255;85;85m"
C_WHITE="\033[38;2;220;220;220m"
C_DIM="\033[2m"
C_R="\033[0m"
SEP=" ${C_DIM}│${C_R} "

# --- Parse JSON input ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"' | sed 's/ (.*context)//')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
used_int=$(printf "%.0f" "$used_pct")
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
dur_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_rm=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# --- Project name detection ---
# Customize: add your own project directories here
cwd=$(pwd)
proj=""
for dir in "$HOME/Desktop" "$HOME/Projects" "$HOME/Documents" "$HOME/Developer"; do
  if [[ "$cwd" == "$dir/"* ]]; then
    proj=$(echo "$cwd" | sed "s|$dir/||" | cut -d'/' -f1)
    break
  fi
done

# --- Tokens (human readable) ---
fmt_tok() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    echo "$(echo "$n" | awk '{printf "%.1fM", $1/1000000}')"
  elif [ "$n" -ge 1000 ]; then
    echo "$(echo "$n" | awk '{printf "%.0fK", $1/1000}')"
  else
    echo "$n"
  fi
}
in_str=$(fmt_tok "$total_in")
out_str=$(fmt_tok "$total_out")

# --- Cost ---
cost_str=$(echo "$cost_usd" | awk '{
  if ($1 >= 1) printf "$%.2f", $1
  else if ($1 >= 0.01) printf "$%.2f", $1
  else printf "$%.3f", $1
}')

# --- Duration ---
dur_min=$(( dur_ms / 60000 ))
dur_sec=$(( (dur_ms % 60000) / 1000 ))
if [ "$dur_min" -ge 60 ]; then
  dur_hr=$(( dur_min / 60 ))
  dur_rm=$(( dur_min % 60 ))
  dur_str="${dur_hr}h${dur_rm}m"
elif [ "$dur_min" -gt 0 ]; then
  dur_str="${dur_min}m"
else
  dur_str="${dur_sec}s"
fi

# --- Effort level ---
effort=$(jq -r '.effortLevel // "default"' ~/.claude/settings.json 2>/dev/null)
case "$effort" in
  max)  effort_color="$C_RED"; effort_label="MAX" ;;
  high) effort_color="$C_ORANGE"; effort_label="HIGH" ;;
  medium|default) effort_color="$C_YELLOW"; effort_label="MED" ;;
  low)  effort_color="$C_GREEN"; effort_label="LOW" ;;
  *)    effort_color="$C_DIM"; effort_label="$effort" ;;
esac
effort_str="${effort_color}${effort_label}${C_R}"

# --- Context usage bar (filled ● / empty ○) ---
pct_color="$C_GREEN"
[ "$used_int" -ge 50 ] && pct_color="$C_ORANGE"
[ "$used_int" -ge 70 ] && pct_color="$C_YELLOW"
[ "$used_int" -ge 90 ] && pct_color="$C_RED"

bar_filled=$(( used_int / 10 ))
bar_empty=$(( 10 - bar_filled ))
bar=""
for i in $(seq 1 $bar_filled); do bar="${bar}●"; done
for i in $(seq 1 $bar_empty); do bar="${bar}${C_DIM}○${C_R}${pct_color}"; done
ctx_str="${pct_color}${bar} ${used_int}%${C_R}"

# --- Rate limit (5-hour window) ---
rl_str=""
if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  rl_color="$C_GREEN"
  [ "$five_int" -ge 50 ] && rl_color="$C_ORANGE"
  [ "$five_int" -ge 70 ] && rl_color="$C_YELLOW"
  [ "$five_int" -ge 90 ] && rl_color="$C_RED"
  rl_str="${SEP}${rl_color}5h ${five_int}%${C_R}"
fi

# --- Assemble output ---
out=""

# Project name (if detected)
if [ -n "$proj" ]; then
  out="${C_CYAN}${proj}${C_R}${SEP}"
fi

# Model + Effort
out="${out}${C_BLUE}${model}${C_R}${SEP}${effort_str}"

# Context
out="${out}${SEP}${ctx_str}"

# Tokens
out="${out}${SEP}${C_DIM}in${C_R}${C_WHITE}${in_str}${C_R} ${C_DIM}out${C_R}${C_WHITE}${out_str}${C_R}"

# Lines changed (only if > 0)
if [ "$lines_add" -gt 0 ] || [ "$lines_rm" -gt 0 ]; then
  out="${out}${SEP}${C_GREEN}+${lines_add}${C_R} ${C_RED}-${lines_rm}${C_R}"
fi

# Duration
out="${out}${SEP}${C_DIM}⏱${C_R} ${C_WHITE}${dur_str}${C_R}"

# Cost
out="${out}${SEP}${C_WHITE}${cost_str}${C_R}"

# Rate limit
out="${out}${rl_str}"

# Paw!
out="${out} 🐾"

echo -e "$out"
