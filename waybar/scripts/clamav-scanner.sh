#!/usr/bin/env bash
# =============================================================================
# Malware Scanner – Omarchy Walker Edition
# =============================================================================

# Dependency Check
for cmd in walker alacritty zenity clamscan freshclam; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "Scanner Error" "Missing dependency: $cmd"
    fi
done

# Walker prompt helper
menu() {
    local prompt="$1"
    local options="$2"
    echo -e "$options" | omarchy-launch-walker --dmenu -p "$prompt" --width 500 --maxheight 400
}

# Helper: Run commands in detected terminal
detect_terminal() {
    if command -v alacritty &>/dev/null; then
        echo "alacritty --class OmarchyFloatingTerm --title"
    elif command -v ghostty &>/dev/null; then
        echo "ghostty --title"
    elif command -v kitty &>/dev/null; then
        echo "kitty --title"
    elif command -v foot &>/dev/null; then
        echo "foot -T"
    else
        notify-send "Error" "No terminal found!"
        exit 1
    fi
}

run_in_term() {
    local term_cmd=$(detect_terminal)
    local title="$1"
    local cmd="$2"
    walker --close 2>/dev/null
    $term_cmd "$title" -e bash -c "
        echo -e '\e[38;2;198;160;246m\e[1m✦ $title\e[0m'
        echo -e '\e[38;2;110;115;141m╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌\e[0m\n'
        $cmd
        echo -e '\n\e[2mProcess finished. Press any key to close...\e[0m'
        read -n 1
    " &
}

# --- Main Logic ---
options="📂 Scan a Directory\n🔄 Update Virus Definitions\n📄 View Last Scan Log\n📦 Install Dependencies\n🚪 Exit"

chosen=$(menu "󰒔 Scanner" "$options")

[[ -z "$chosen" || "$chosen" == *"Exit"* ]] && exit 0

case "$chosen" in
    *"Scan a Directory"*)
        target=$(zenity --file-selection --directory --title="Select folder to scan")
        if [[ -n "$target" ]]; then
            if zenity --question --title="Safe Mode" --text="Remove infected files?" --ok-label="Remove" --cancel-label="Report Only"; then
                flag="--remove=yes"
            else
                flag=""
            fi
            logfile="/tmp/clamscan_$(date +%Y%m%d_%H%M%S).log"
            run_in_term "Virus Scan" "sudo clamscan --recursive --infected --verbose $flag --log=$logfile '$target'"
        fi
        ;;

    *"Update Virus Definitions"*)
        run_in_term "ClamAV Update" "sudo freshclam"
        ;;

    *"View Last Scan Log"*)
        latest_log=$(ls -t /tmp/clamscan_*.log 2>/dev/null | head -1)
        if [[ -n "$latest_log" ]]; then
            run_in_term "Scan Log: $(basename "$latest_log")" "sudo cat '$latest_log'"
        else
            notify-send "Scanner" "No log files found."
        fi
        ;;

    *"Install Dependencies"*)
        run_in_term "Install Dependencies" "sudo pacman -S --needed --noconfirm clamav walker alacritty zenity"
        ;;
esac
