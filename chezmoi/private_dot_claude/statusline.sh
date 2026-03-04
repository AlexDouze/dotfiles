#!/bin/bash
# Line 1: Model | tokens used/total | $cost | thinking: on/off | +lines_added -lines_removed
# Line 2: session ID

set -f  # disable globbing

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# ANSI colors matching oh-my-posh theme
blue='\033[38;2;0;153;255m'
orange='\033[38;2;255;176;85m'
green='\033[38;2;0;160;0m'
cyan='\033[38;2;46;149;153m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
dim='\033[2m'
reset='\033[0m'

# Format token counts (e.g., 50k / 200k)
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

# ===== Extract data from JSON =====
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')

# Context window
size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
[ "$size" -eq 0 ] 2>/dev/null && size=200000

# Token usage
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens $current)
total_tokens=$(format_tokens $size)

# Cost
cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost_fmt=$(awk "BEGIN {printf \"%.3f\", $cost_raw}")
cost_int=$(awk "BEGIN {printf \"%d\", $cost_raw}")

# Lines changed
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Session ID
session_id=$(echo "$input" | jq -r '.session_id // ""')

# Check thinking status
thinking_on=false
settings_path="$HOME/.claude/settings.json"
if [ -f "$settings_path" ]; then
    thinking_val=$(jq -r '.alwaysThinkingEnabled // false' "$settings_path" 2>/dev/null)
    [ "$thinking_val" = "true" ] && thinking_on=true
fi

# ===== LINE 1: Model | tokens | $cost | thinking | +lines -lines =====
sep=" ${dim}|${reset} "
line1=""
line1+="${blue}${model_name}${reset}"
line1+="${sep}"
line1+="${orange}${used_tokens} / ${total_tokens}${reset}"
line1+="${sep}"

# Cost: yellow if >= $1, otherwise green
if [ "$cost_int" -ge 1 ] 2>/dev/null; then
    line1+="${yellow}\$${cost_fmt}${reset}"
else
    line1+="${green}\$${cost_fmt}${reset}"
fi

line1+="${sep}"
line1+="thinking: "
if $thinking_on; then
    line1+="${orange}On${reset}"
else
    line1+="${dim}Off${reset}"
fi

line1+="${sep}"
line1+="${green}+${lines_added}${reset} ${red}-${lines_removed}${reset}"

# ===== LINE 2: Session ID =====
line2="${dim}${white}${session_id}${reset}"

# Output all lines
printf "%b" "$line1"
printf "\n%b" "$line2"

exit 0
