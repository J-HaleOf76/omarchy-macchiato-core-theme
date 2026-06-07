#!/usr/bin/env bash
# =============================================================================
# MAC Address Spoofer – Omarchy Walker Edition
# =============================================================================

# Dependency Check
for cmd in walker alacritty zenity macchanger ip notify-send; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "Spoofer Warning" "Missing dependency: $cmd. Use the 'Install' option."
    fi
done

# Walker prompt helper
menu() {
    local prompt="$1"
    local options="$2"
    echo -e "$options" | omarchy-launch-walker --dmenu -p "$prompt" --width 500 --maxheight 500
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
    local notify_msg="$3"

    walker --close 2>/dev/null
    $term_cmd "$title" -e bash -c "
        echo -e '\e[38;2;198;160;246m\e[1m✦ $title\e[0m'
        echo -e '\e[38;2;110;115;141m╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌\e[0m\n'
        $cmd
        echo -e '\n\e[32;1m✔ DONE!\e[0m'
        [[ -n \"$notify_msg\" ]] && notify-send 'Spoofer' \"$notify_msg\"
        echo -e '\n\e[2mTask finished. Press any key to close...\e[0m'
        read -n 1
    "
}

# --- Logic: Get Interfaces ---
get_interfaces() {
    ip link show | awk -F': ' '/^[0-9]+: (e|w|en|wl)/ {print $2}' | grep -v lo
}

# --- Main Logic ---
while true; do
    ifaces=$(get_interfaces)
    iface_list=""

    for i in $ifaces; do
        mac=$(ip link show "$i" | awk '/link\/ether/ {print $2}')
        iface_list+="🌐 $i  ($mac)\n"
    done

    iface_list+="📦 Install Dependencies\n"
    iface_list+="🚪 Exit"

    selected_row=$(menu "Select Interface" "$iface_list")

    [[ -z "$selected_row" || "$selected_row" == *"Exit"* ]] && exit 0

    if [[ "$selected_row" == *"Install Dependencies"* ]]; then
        run_in_term "Dependency Installer" "sudo pacman -S --needed --noconfirm macchanger walker alacritty zenity libnotify iproute2" "Dependencies installed successfully."
        continue
    fi

    iface=$(echo "$selected_row" | awk '{print $2}')

    actions="🎲 Random MAC\n🏭 Vendor MAC\n✏️  Specific MAC\n♻️  Restore Original\n↩ Back"

    action_choice=$(menu "Action: $iface" "$actions")

    [[ -z "$action_choice" || "$action_choice" == *"Back"* ]] && continue

    case "$action_choice" in
        *"Random"*)   cmd="sudo macchanger -r $iface" ;;
        *"Vendor"*)   cmd="sudo macchanger -A $iface" ;;
        *"Restore"*)  cmd="sudo macchanger -p $iface" ;;
        *"Specific"*)
            custom_mac=$(zenity --entry --title="Custom MAC" --text="Enter MAC (XX:XX:XX:XX:XX:XX):")
            if [[ -n "$custom_mac" ]]; then
                cmd="sudo macchanger -m $custom_mac $iface"
            else
                continue
            fi
            ;;
    esac

    run_in_term "MAC Spoofer: $iface" "
        echo -e '\e[33mSetting interface down...\e[0m'
        sudo ip link set $iface down
        echo -e '\e[33mApplying new MAC...\e[0m'
        $cmd
        echo -e '\e[33mSetting interface up...\e[0m'
        sudo ip link set $iface up
        echo -e '\n\e[32m✔ Final Status:\e[0m'
        ip link show $iface | grep ether
    " "MAC change for $iface is DONE!"
done
