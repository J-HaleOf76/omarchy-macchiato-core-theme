#!/usr/bin/env bash
# =============================================================================
# WireGuard Manager – Omarchy Terminal Edition
# =============================================================================

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

# --- 2. Unified Terminal Execution ---
run_in_term() {
    local term_cmd=$(detect_terminal)
    local title="$1"
    local cmd="$2"

    walker --close 2>/dev/null
    $term_cmd "$title" -e bash -c "
        echo -e '\e[38;2;198;160;246m\e[1m✦ $title\e[0m'
        echo -e '\e[38;2;110;115;141m╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌\e[0m\n'
        $cmd
        echo -e '\n\e[2mPress any key to close...\e[0m'
        read -n 1
    "
}

# --- 3. Terminal Editor for Config ---
edit_config() {
    local conf="/etc/wireguard/wg0.conf"
    local term_cmd=$(detect_terminal)
    detect_terminal_editor() {
        for e in nano vim vi; do
            command -v "$e" &>/dev/null && echo "$e" && return
        done
        echo "nano"
    }

    local editor=$(detect_terminal_editor)

    if [[ ! -f "$conf" ]]; then
        echo "# Paste [Interface] and [Peer] here" | sudo tee "$conf" > /dev/null
        sudo chmod 600 "$conf"
    fi

    walker --close 2>/dev/null
    $term_cmd "WireGuard Config" -e bash -c "
        echo -e '\e[38;2;198;160;246m\e[1m✦ Editing WireGuard Config\e[0m'
        echo -e '\e[38;2;110;115;141m╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌\e[0m\n'
        sudo $editor $conf
        echo -e '\n\e[32m✔ Config saved. Press any key to close...\e[0m'
        read -n 1
    "
}

# Connection Status check
if ip link show wg0 &>/dev/null; then
    STATUS="[CONNECTED]"
else
    STATUS=""
fi

# Main Menu
options="🟢 Connect VPN\n🔴 Disconnect VPN\n🌐 Check IP & Location\n📊 Show Details\n📝 Edit Config\n📦 Install Dependencies\n🎁 Fetch Free Configs\n🚪 Exit"

chosen=$(menu "WireGuard $STATUS" "$options")

[[ -z "$chosen" || "$chosen" == *"Exit"* ]] && exit 0

case "$chosen" in
    *"Connect VPN"*)
        run_in_term "VPN Connect" "
            sudo pacman -S --needed --noconfirm openresolv
            sudo systemctl enable --now systemd-resolved
            sudo resolvconf -u

            echo -e '\e[34mRetrying until connected...\e[0m'
            sudo wg-quick down wg0 >/dev/null 2>&1
            until sudo wg-quick up wg0 2>&1; do
                sudo resolvconf -u 2>/dev/null
                echo -e '\e[33m✘ Failed. Retrying in 3 seconds...\e[0m'
                sleep 3
            done
            echo -e '\n\e[32m✔ Connected successfully!\e[0m'
            echo -e '\n\e[36m─── IP Details ───\e[0m'
            curl -s http://ip-api.com/json/ | jq -r '\"IP: \(.query)\nLocation: \(.city), \(.regionName) (\(.country))\nISP: \(.isp)\"'
        "
        ;;

    *"Disconnect VPN"*)
        run_in_term "VPN Disconnect" "
            if ip link show wg0 &>/dev/null; then
                sudo wg-quick down wg0
                echo -e '\n\e[32m✔ VPN Stopped.\e[0m'
            else
                echo -e '\e[31m✘ wg0 is not currently active.\e[0m'
            fi
        "
        ;;

    *"Edit Config"*)
        edit_config
        ;;

    *"Fetch Free Configs"*)
        sub_options="⭐ VPNBook (Recommended)\n🌐 SSHStores\n🌐 VPNJantit\n↩ Back"
        sub_choice=$(menu "Free Configs" "$sub_options")

        case "$sub_choice" in
            *"VPNBook"*) xdg-open "https://www.vpnbook.com/freevpn/wireguard-vpn" ;;
            *"SSHStores"*) xdg-open "https://sshstores.net/wireguard" ;;
            *"VPNJantit"*) xdg-open "https://www.vpnjantit.com/free-wireguard" ;;
            *"Back"*) exec "$0" ;;
        esac
        ;;

    *"Install Dependencies"*)
        run_in_term "Installer" "sudo pacman -S --needed --noconfirm wireguard-tools openresolv jq curl walker"
        ;;

    *"Check IP"*)
        run_in_term "IP Check" "curl -s http://ip-api.com/json/ | jq -r '\"IP: \(.query)\nLocation: \(.city), \(.regionName)\nISP: \(.isp)\"'"
        ;;

    *"Show Details"*)
        run_in_term "Details" "sudo wg show"
        ;;
esac
