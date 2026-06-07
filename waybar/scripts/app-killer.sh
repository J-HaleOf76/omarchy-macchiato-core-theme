#!/usr/bin/env bash
# ============================================================================
# Omarchy Task Manager - Walker Edition
# ============================================================================

# Colors from your Omarchy palette
MAUVE="#c6a0f6"
BASE="#24273a"
TEXT="#cad3f5"
SURFACE="#363a4f"
RED="#ed8796"
SUBTEXT="#a5adce"

# 1. Fetch process list, filter system apps, and sort
process_data=$(ps -eo pid,pcpu,pmem,comm --sort=-pcpu --no-headers | \
    grep -vE "(Hyprland|waybar|swaync|dbus|systemd|kworker|sh|ps|awk|grep|walker)" | \
    awk '{printf "%-7s  %-8s  %-8s  %s\n", $1, $2"%", $3"%", $4}')

# 2. Launch Walker with process list
selected=$(echo -e "$process_data" | omarchy-launch-walker --dmenu -p "󰓅 Tasks" --width 600 --maxheight 500)

[[ -z "$selected" ]] && exit 0

pid=$(echo "$selected" | awk '{print $1}')
pname=$(echo "$selected" | awk '{print $4}')

# 3. Execution Protocol
action=$(echo -e "🛑 Terminate (SIGTERM)\n🔪 Force Kill (SIGKILL)\n↩ Cancel" | omarchy-launch-walker --dmenu -p "Kill $pname?" --width 400 --maxheight 300)

case "$action" in
    *"Terminate"*) kill "$pid" && notify-send "Task Manager" "Sent SIGTERM" ;;
    *"Kill"*) kill -9 "$pid" && notify-send "Task Manager" "Sent SIGKILL" ;;
esac
