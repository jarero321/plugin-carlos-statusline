#!/usr/bin/env bash
# carlos-statusline v4.0: DX-first statusline for Claude Code
# Designed around what matters: limits, context, model, agent, changes
# Numbers only appear as warnings — bars and color do the talking
#
# Layout:
#  Opus 4.6 ┊ ctx ━━╸──── ┊ 5h ━━━╸── ┊ 7d ━╸──── ┊ 5x ┊ +142 -38 ┊  Go  main
# When limits are critical, % appears:
#  Opus 4.6 ┊ ctx ━━━━━╸─ 72% ┊ 5h ━━━━━━╸ 89% ┊ 7d ━━╸──── ┊  Go  main

set -euo pipefail

# ── ANSI ────────────────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
FG_RED='\033[31m'
FG_GREEN='\033[32m'
FG_YELLOW='\033[33m'
FG_CYAN='\033[36m'
FG_WHITE='\033[37m'
FG_MAGENTA='\033[35m'

# ── Config ──────────────────────────────────────────────────────────────────
USAGE_CACHE_TTL=300
[[ -f "$HOME/.config/carlos-statusline/config" ]] && source "$HOME/.config/carlos-statusline/config" 2>/dev/null

USAGE_CACHE_DIR="$HOME/.cache/carlos-statusline"
USAGE_CACHE_FILE="$USAGE_CACHE_DIR/usage.json"

# ── Stdin ───────────────────────────────────────────────────────────────────
json=$(cat)

# ── JSON parser ─────────────────────────────────────────────────────────────
jval() {
    local key="$1" default="$2" value
    value=$(echo "$json" | grep -oP "\"$key\"\s*:\s*\"\K[^\"]*" 2>/dev/null | head -1)
    [[ -z "$value" ]] && value=$(echo "$json" | grep -oP "\"$key\"\s*:\s*\K-?[0-9]+\.?[0-9]*" 2>/dev/null | head -1)
    [[ -z "$value" ]] && value=$(echo "$json" | grep -oP "\"$key\"\s*:\s*\K(true|false|null)" 2>/dev/null | head -1)
    echo "${value:-$default}"
}

# ── Helpers ─────────────────────────────────────────────────────────────────

# Color for a percentage: green < 50, yellow < 75, red >= 75
pct_color() {
    local p="${1:-0}"; p="${p%.*}"; [[ ! "$p" =~ ^[0-9]+$ ]] && p=0
    if [[ $p -lt 50 ]]; then echo -n "$FG_GREEN"
    elif [[ $p -lt 75 ]]; then echo -n "$FG_YELLOW"
    else echo -n "$FG_RED"; fi
}

# Mini progress bar: label ━━━╸──── [%]
# Shows % only when >= threshold (default 70)
mini_bar() {
    local label="$1" pct="$2" width="${3:-7}" warn_at="${4:-70}"
    pct="${pct%.*}"; [[ ! "$pct" =~ ^[0-9]+$ ]] && pct=0
    [[ $pct -gt 100 ]] && pct=100

    local color; color=$(pct_color "$pct")
    local filled=$(( pct * width / 100 ))
    local bar=""

    # Filled
    if [[ $filled -gt 0 ]]; then
        bar+="${color}"
        for ((i = 0; i < filled; i++)); do bar+="━"; done
    fi

    # Cap + empty
    if [[ $filled -lt $width ]]; then
        if [[ $pct -gt 0 ]]; then
            bar+="${color}╸${RESET}${DIM}"
            local rem=$(( width - filled - 1 ))
        else
            bar+="${DIM}"
            local rem=$width
        fi
        for ((i = 0; i < rem; i++)); do bar+="─"; done
        bar+="${RESET}"
    else
        bar+="${RESET}"
    fi

    # Output: label bar [%]
    local out="${DIM}${label}${RESET} ${bar}"
    if [[ $pct -ge $warn_at ]]; then
        out+=" ${color}${pct}%${RESET}"
    fi
    echo -n "$out"
}

format_time() {
    local ms="${1:-0}"; ms="${ms%.*}"; [[ ! "$ms" =~ ^[0-9]+$ ]] && ms=0
    local s=$(( ms / 1000 ))
    if [[ $s -ge 3600 ]]; then echo "$(( s / 3600 ))h$(( (s % 3600) / 60 ))m"
    elif [[ $s -ge 60 ]]; then echo "$(( s / 60 ))m"
    else echo "${s}s"; fi
}

# ── Extract ─────────────────────────────────────────────────────────────────

model_name=$(jval "display_name" "Unknown")
ctx_pct=$(jval "used_percentage" "0")
cost_usd=$(jval "total_cost_usd" "0")
duration_ms=$(jval "total_duration_ms" "0")
lines_added=$(jval "total_lines_added" "0")
lines_removed=$(jval "total_lines_removed" "0")
workspace=$(jval "current_dir" "$HOME")

# ── Derived ─────────────────────────────────────────────────────────────────

# Git branch + PR
git_branch=""
git_pr=""
if [[ -d "$workspace/.git" ]] || git -C "$workspace" rev-parse --git-dir &>/dev/null 2>&1; then
    git_branch=$(git -C "$workspace" branch --show-current 2>/dev/null || echo "")
    if [[ -n "$git_branch" ]] && command -v gh &>/dev/null; then
        pr_num=$(gh pr view "$git_branch" --json number --jq '.number' 2>/dev/null || echo "")
        [[ -n "$pr_num" ]] && git_pr="PR #${pr_num}"
    fi
fi

# Agent
agent_name=""
if echo "$json" | grep -q '"agent"' 2>/dev/null; then
    agent_name=$(echo "$json" | grep -A2 '"agent"' 2>/dev/null | grep -oP '"name"\s*:\s*"\K[^"]*' 2>/dev/null | head -1)
fi

# Language detection (by project markers, fast file-existence checks)
lang_icon=""
if [[ -f "$workspace/go.mod" ]]; then                                lang_icon=" Go"
elif [[ -f "$workspace/tsconfig.json" ]]; then                       lang_icon=" TS"
elif [[ -f "$workspace/package.json" ]]; then                        lang_icon=" JS"
elif [[ -f "$workspace/Cargo.toml" ]]; then                          lang_icon=" Rust"
elif [[ -f "$workspace/pyproject.toml" ]] || \
     [[ -f "$workspace/requirements.txt" ]] || \
     [[ -f "$workspace/setup.py" ]]; then                            lang_icon=" Py"
elif [[ -f "$workspace/composer.json" ]]; then                       lang_icon=" PHP"
elif [[ -f "$workspace/Gemfile" ]]; then                             lang_icon=" Ruby"
elif ls "$workspace"/*.csproj &>/dev/null || \
     ls "$workspace"/*.sln &>/dev/null; then                         lang_icon="󰌛 C#"
elif [[ -f "$workspace/pom.xml" ]] || \
     [[ -f "$workspace/build.gradle" ]]; then                        lang_icon=" Java"
elif [[ -f "$workspace/pubspec.yaml" ]]; then                        lang_icon=" Dart"
elif [[ -f "$workspace/mix.exs" ]]; then                             lang_icon=" Elixir"
elif [[ -f "$workspace/Package.swift" ]]; then                       lang_icon="󰛥 Swift"
elif [[ -f "$workspace/CMakeLists.txt" ]] || \
     [[ -f "$workspace/Makefile" ]]; then                            lang_icon=" C/C++"
fi

# Plan tier
plan_tier=""
creds_file="$HOME/.claude/.credentials.json"
if [[ -f "$creds_file" ]]; then
    rate_tier=$(grep -oP '"rateLimitTier"\s*:\s*"\K[^"]*' "$creds_file" 2>/dev/null | head -1)
    case "$rate_tier" in
        *max_20x*) plan_tier="20x" ;;
        *max_5x*)  plan_tier="5x" ;;
        *pro*)     plan_tier="Pro" ;;
        *)         plan_tier="" ;;
    esac
fi

# Usage API (cached, bg refresh)
session_util=""
weekly_util=""
if [[ -f "$creds_file" ]]; then
    oauth_token=$(grep -oP '"accessToken"\s*:\s*"\K[^"]*' "$creds_file" 2>/dev/null | head -1)

    need_refresh=true
    if [[ -f "$USAGE_CACHE_FILE" ]]; then
        cache_age=$(( $(date +%s) - $(stat -c %Y "$USAGE_CACHE_FILE" 2>/dev/null || echo "0") ))
        [[ $cache_age -lt $USAGE_CACHE_TTL ]] && need_refresh=false
    fi

    if $need_refresh && [[ -n "$oauth_token" ]]; then
        mkdir -p "$USAGE_CACHE_DIR" 2>/dev/null
        (curl -s -m 5 "https://api.anthropic.com/api/oauth/usage" \
            -H "Authorization: Bearer $oauth_token" \
            -H "Content-Type: application/json" \
            -H "anthropic-beta: oauth-2025-04-20" \
            > "$USAGE_CACHE_FILE.tmp" 2>/dev/null \
            && mv "$USAGE_CACHE_FILE.tmp" "$USAGE_CACHE_FILE") &
    fi

    if [[ -f "$USAGE_CACHE_FILE" ]]; then
        usage_data=$(tr -d '\n' < "$USAGE_CACHE_FILE" 2>/dev/null)
        session_util=$(echo "$usage_data" | grep -oP '"five_hour"\s*:\s*\{[^}]*"utilization"\s*:\s*\K[0-9.]+' 2>/dev/null | head -1 || echo "")
        weekly_util=$(echo "$usage_data" | grep -oP '"seven_day"\s*:\s*\{[^}]*"utilization"\s*:\s*\K[0-9.]+' 2>/dev/null | head -1 || echo "")
    fi
fi

# ── Integer conversions ────────────────────────────────────────────────────

to_int() { local v="${1%.*}"; v="${v:-0}"; [[ ! "$v" =~ ^[0-9]+$ ]] && v=0; echo "$v"; }

ctx_pct_int=$(to_int "$ctx_pct")
session_int=$(to_int "$session_util")
weekly_int=$(to_int "$weekly_util")
lines_add=$(to_int "$lines_added")
lines_rem=$(to_int "$lines_removed")

# ── Colors ──────────────────────────────────────────────────────────────────

case "$model_name" in
    *Opus*|*opus*)     model_color="${FG_CYAN}" ;;
    *Sonnet*|*sonnet*) model_color="${FG_GREEN}" ;;
    *Haiku*|*haiku*)   model_color="${FG_YELLOW}" ;;
    *)                 model_color="${FG_WHITE}" ;;
esac

cost_cmp=$(echo "$cost_usd" | awk '{printf "%.0f", $1 * 100}' 2>/dev/null || echo "0")
[[ ! "$cost_cmp" =~ ^[0-9]+$ ]] && cost_cmp=0
if [[ $cost_cmp -lt 200 ]]; then cost_color="${FG_WHITE}"
elif [[ $cost_cmp -lt 500 ]]; then cost_color="${FG_YELLOW}"
else cost_color="${FG_RED}"; fi

case "$plan_tier" in
    *20x*) tier_color="${FG_CYAN}" ;;
    *5x*)  tier_color="${FG_GREEN}" ;;
    *Pro*) tier_color="${FG_YELLOW}" ;;
    *)     tier_color="${FG_WHITE}" ;;
esac

# ── Format ──────────────────────────────────────────────────────────────────

cost_fmt=$(printf "%.2f" "$cost_usd" 2>/dev/null || echo "0.00")
session_time=$(format_time "$duration_ms")

# ── Layout ──────────────────────────────────────────────────────────────────

SEP=" ${DIM}┊${RESET} "
COLS=${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}

output=""

# ── 1. Agent mode indicator (prominent, first thing you see) ────────────
if [[ -n "$agent_name" ]]; then
    output+="${BOLD}${FG_MAGENTA} ${agent_name}${RESET}${SEP}"
fi

# ── 2. Model:  Opus 4.6 ────────────────────────────────────────────────
output+="${BOLD}${model_color} ${model_name}${RESET}"

# ── 3. Context window: ctx ━━╸──── [%] ─────────────────────────────────
output+="${SEP}$(mini_bar "ctx" "$ctx_pct_int" 7 70)"

# ── 4. Session limit (5h): 5h ━━━╸── [%] ──────────────────────────────
if [[ -n "$session_util" ]]; then
    output+="${SEP}$(mini_bar "5h" "$session_int" 6 70)"
fi

# ── 5. Weekly limit (7d): 7d ━╸──── [%] ───────────────────────────────
if [[ -n "$weekly_util" ]]; then
    output+="${SEP}$(mini_bar "7d" "$weekly_int" 6 70)"
fi

# ── 6. Plan tier: 5x ──────────────────────────────────────────────────
if [[ -n "$plan_tier" ]]; then
    output+="${SEP}${tier_color}${plan_tier}${RESET}"
fi

# ── 7. Files changed: +142 -38 ────────────────────────────────────────
if [[ $lines_add -gt 0 || $lines_rem -gt 0 ]]; then
    output+="${SEP}${FG_GREEN}+${lines_add}${RESET} ${FG_RED}-${lines_rem}${RESET}"
fi

# ── 8. Language + Git branch:  Go  main ──────────────────────────
if [[ -n "$lang_icon" || -n "$git_branch" ]]; then
    output+="${SEP}"
    [[ -n "$lang_icon" ]] && output+="${FG_CYAN}${lang_icon}${RESET}"
    if [[ -n "$git_branch" ]]; then
        [[ -n "$lang_icon" ]] && output+=" "
        output+="${DIM} ${git_branch}${RESET}"
        [[ -n "$git_pr" ]] && output+=" ${FG_MAGENTA}${git_pr}${RESET}"
    fi
fi

# ── 9. Wide terminal extras (>100 cols) ────────────────────────────────
if [[ $COLS -gt 100 ]]; then
    output+="${SEP}${cost_color}\$${cost_fmt}${RESET}"
    output+="${SEP}${DIM} ${session_time}${RESET}"
fi

echo -en "$output"
