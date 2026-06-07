#!/usr/bin/env bash
# =============================================================================
# YouTube Downloader – Omarchy Walker Edition
# =============================================================================

# Configuration
DOWNLOAD_DIR="$HOME/Downloads/YouTube"
DEFAULT_COOKIE_FILE="$HOME/.config/yt-dlp/cookies.txt"
CURRENT_COOKIES="$DEFAULT_COOKIE_FILE"

mkdir -p "$DOWNLOAD_DIR"

# Walker prompt helper
menu() {
    local prompt="$1"
    local options="$2"
    echo -e "$options" | omarchy-launch-walker --dmenu -p "$prompt" --width 500 --maxheight 500
}

# --- 1. Automatic Terminal Detection ---
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

# Helper: Install dependencies
install_deps() {
    local term_cmd=$(detect_terminal)
    walker --close 2>/dev/null
    $term_cmd "Omarchy Dependency Installer" -e bash -c "
        echo -e '\e[38;2;198;160;246m\e[1m✦ Installing Dependencies...\e[0m'
        echo -e '\e[38;2;110;115;141m╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌\e[0m\n'
        sudo pacman -S --needed --noconfirm yt-dlp ffmpeg walker zenity libnotify
        echo -e '\n\e[32m✔ Process complete.\e[0m'
        echo -e '\nPress any key to close...'
        read -n 1
    " &
}

# Function to handle cookie selection via GUI
manage_cookies() {
    local options="🍪 Use Default\n📂 Select Manually\n🧩 Install Cookie Extension\n↩ Back"
    local choice=$(menu "Cookies" "$options")

    case "$choice" in
        *"Use Default"*)
            CURRENT_COOKIES="$DEFAULT_COOKIE_FILE"
            notify-send "Omarchy" "Switched to default cookies."
            ;;
        *"Select Manually"*)
            local manual_file=$(zenity --file-selection --title="Select cookies.txt" --file-filter="*.txt")
            if [[ -n "$manual_file" ]]; then
                CURRENT_COOKIES="$manual_file"
                notify-send "Omarchy" "Cookies set to: $(basename "$manual_file")"
            fi
            ;;
        *"Install Cookie Extension"*)
            xdg-open "https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc" &
            notify-send "Omarchy" "Opening browser to install extension..."
            ;;
        *"Back"*)
            return
            ;;
    esac
}

run_download() {
    local format="$1"
    local merge_opts="$2"
    local playlist="$3"
    local term_cmd=$(detect_terminal)
    local cookie_cmd=""
    local playlist_opts=""

    [[ -f "$CURRENT_COOKIES" ]] && cookie_cmd="--cookies $CURRENT_COOKIES"
    [[ "$playlist" == "yes" ]] && playlist_opts="--yes-playlist"

    walker --close 2>/dev/null

    $term_cmd "Omarchy Downloader" -e bash -c "
        echo -e '\e[38;2;198;160;246m\e[1m✦ Omarchy YouTube Downloader\e[0m'
        echo -e '\e[38;2;110;115;141m╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌\e[0m\n'

        read -e -p \$'\\e[36mPaste URL: \\e[0m' url
        [[ -z \"\$url\" ]] && echo -e '\n\e[31mNo URL entered.\e[0m' && read -n 1 && exit

        echo -e '\n\e[38;2;110;115;141mDownloading...\e[0m\n'

        cd '$DOWNLOAD_DIR'

        yt-dlp $cookie_cmd $merge_opts $playlist_opts -f '$format' -o '%(title)s.%(ext)s' \"\$url\"
        exit_code=\$?

        if [ \$exit_code -eq 0 ]; then
            echo -e '\n\e[32m✔ Download Complete!\e[0m'
        else
            echo -e '\n\e[31m✘ Download Failed. Check URL or cookies.\e[0m'
        fi
        echo -e '\nPress any key to close...'
        read -n 1
    " &
}

# --- Main Menu Loop ---
while true; do
    options="🎬 Video + Audio\n🎵 Audio Only\n🎞️ Video Only\n📋 Playlist (Video + Audio)\n📋 Playlist (Audio Only)\n⚙️ Cookie Settings\n🛠️ Install Dependencies\n🚪 Exit"
    chosen=$(menu "󰗃 YT-DL" "$options")

    [[ -z "$chosen" || "$chosen" == *"Exit"* ]] && exit 0

    case "$chosen" in
        *"Install Dependencies"*)
            install_deps
            continue
            ;;
        *"Cookie Settings"*)
            manage_cookies
            continue
            ;;
    esac

    case "$chosen" in
        *"Playlist (Video + Audio)"*) run_download "bestvideo+bestaudio/best" "--merge-output-format mp4" "yes" ;;
        *"Playlist (Audio Only)"*)    run_download "bestaudio" "--extract-audio --audio-format m4a" "yes" ;;
        *"Video + Audio"*) run_download "bestvideo+bestaudio/best" "--merge-output-format mp4" "no" ;;
        *"Audio Only"*)    run_download "bestaudio" "--extract-audio --audio-format m4a" "no" ;;
        *"Video Only"*)    run_download "bestvideo" "" "no" ;;
    esac
done
