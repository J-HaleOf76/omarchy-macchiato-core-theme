#!/usr/bin/env bash
# =============================================================================
# Omarchy Macchiato – Advanced Settings & Cleaner (Walker Edition)
# =============================================================================

DIR="$HOME/.config/waybar/scripts"
WG="$DIR/wg-manager.sh"
YT="$DIR/yt-dl.sh"
KILLER="$DIR/app-killer.sh"
SCAN="$DIR/clamav-scanner.sh"
SPOOF="$DIR/mac-spoofer.sh"
METADATA="$DIR/metadata_cleaner.sh"
SHREDDER="$DIR/shredder.sh"


menu() {
    local prompt="$1"
    local options="$2"
    echo -e "$options" | omarchy-launch-walker --dmenu -p "$prompt" --width 400 --maxheight 500
}

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

run_install() {
    local term_cmd=$(detect_terminal)
    walker --close 2>/dev/null
    $term_cmd "Omarchy Installer" -e bash -c "
        echo -e '\e[38;2;198;160;246m✦ Installing Omarchy Dependencies...\e[0m'
        sudo pacman -S --needed --noconfirm mat2 perl-image-exiftool wireguard-tools openresolv jq curl zenity walker clamav macchanger yt-dlp ffmpeg
        echo -e '\n\e[32m✔ Installation Finished!\e[0m'
        sleep 2
    "
}

run_cleaner() {
    clean_options="🧹 Clear All Cache\n🗑️ Empty Trash\n🛡️ Metadata Cleaner\n💀 Secure Shredder\n📦 Remove Orphan Packages\n↩ Back"
    selected_clean=$(menu "󰃢 Cleaner" "$clean_options")
    case "$selected_clean" in
        *"Clear All Cache"*) rm -rf "$HOME/.cache/"* 2>/dev/null && notify-send "Cleaner" "Cache Purged" ;;
        *"Empty Trash"*)
            local term_cmd=$(detect_terminal)
            walker --close 2>/dev/null
            $term_cmd "Emptying Trash" -e bash -c "
                echo -e '\e[38;2;198;160;246m✦ Purging Trash...\e[0m'
                rm -rf \"$HOME/.local/share/Trash/\"* 2>/dev/null
                sleep 0.5
            "
            notify-send "Cleaner" "Done" ;;
        *"Metadata Cleaner"*) [[ -f "$METADATA" ]] && bash "$METADATA" || notify-send "Error" "Metadata script not found" ;;
        *"Secure Shredder"*) [[ -f "$SHREDDER" ]] && bash "$SHREDDER" || notify-send "Error" "Shredder script not found" ;;
        *"Remove Orphan Packages"*)
            local term_cmd=$(detect_terminal)
            walker --close 2>/dev/null
            $term_cmd "Remove Orphans" -e bash -c "sudo pacman -Rs \$(pacman -Qtdq); sleep 1" ;;
        *"Back"*) exec "$0" ;;
    esac
}

options="🔐 WireGuard\n🎬 YouTube DL\n🧹 Omarchy Cleaner\n🔪 App Killer\n🛡️ Scan Malware\n🎭 Spoof MAC\n🛠️ Install Dependencies"
chosen=$(menu "󱄅" "$options")
[[ -z "$chosen" ]] && exit 0
case "$chosen" in
    *"WireGuard"*) bash "$WG" & ;;
    *"YouTube DL"*) bash "$YT" & ;;
    *"Omarchy Cleaner"*) run_cleaner ;;
    *"App Killer"*) bash "$KILLER" & ;;
    *"Scan Malware"*) bash "$SCAN" & ;;
    *"Spoof MAC"*) bash "$SPOOF" & ;;
    *"Install Dependencies"*) run_install ;;
esac
