#!/usr/bin/env bash
# =============================================================================
# Metadata Cleaner – Omarchy Terminal Edition
# =============================================================================

menu() {
    local prompt="$1"
    local options="$2"
    echo -e "$options" | omarchy-launch-walker --dmenu -p "$prompt" --width 500 --maxheight 400
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

size_str() {
    local size=$1
    if ((size > 1073741824)); then
        echo "$(bc -l <<< "scale=2; $size/1073741824") GiB"
    elif ((size > 1048576)); then
        echo "$(bc -l <<< "scale=2; $size/1048576") MiB"
    elif ((size > 1024)); then
        echo "$(bc -l <<< "scale=2; $size/1024") KiB"
    else
        echo "${size} B"
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
        echo -e '\n\e[2mPress any key to close...\e[0m'
        read -n 1
    " &
}

clean_file() {
    local file="$1"
    local mode="${2:-standard}"
    local size_before=$(stat -c%s "$file" 2>/dev/null || echo 0)
    local ret=1

    if command -v exiftool &>/dev/null; then
        if [[ "$mode" == "deep" ]]; then
            exiftool -overwrite_original -all= -AllDates= -ThumbnailImage= -XResolution= -YResolution= "$file" 2>/dev/null
        else
            exiftool -overwrite_original -all= "$file" 2>/dev/null
        fi
        ret=$?
    fi

    if [[ $ret -ne 0 ]] && command -v mat2 &>/dev/null; then
        mat2 "$file" 2>/dev/null
        ret=$?
    fi

    if [[ $ret -eq 0 ]]; then
        local size_after=$(stat -c%s "$file" 2>/dev/null || echo 0)
        local saved=$((size_before - size_after))
        echo -e "\e[32m✔\e[0m Metadata removed  (\e[38;2;147;154;183m-$(size_str $saved)\e[0m)"
        if [[ "$mode" == "deep" ]]; then
            touch -t 197001010000 "$file" 2>/dev/null
            chmod 644 "$file" 2>/dev/null
        fi
        return 0
    else
        echo -e "\e[33m⚠ No tool available to clean this file\e[0m"
        return 1
    fi
}

if [[ "$1" == "--clean-now" ]]; then
    TARGET="$2"
    MODE="$3"

    if [[ "$MODE" == "inspect" ]]; then
        echo -e "\e[38;2;198;160;246m[INSPECTING]\e[0m $TARGET\n"
        if command -v exiftool &>/dev/null; then
            exiftool "$TARGET"
        elif command -v mat2 &>/dev/null; then
            mat2 --show "$TARGET"
        else
            echo -e "\e[31mNo metadata tool found.\e[0m"
            exit 1
        fi
        exit 0
    fi

    local mode="standard"
    [[ "$MODE" == "deep" ]] && mode="deep"

    if [[ -d "$TARGET" ]]; then
        mapfile -t FILES < <(find "$TARGET" -type f 2>/dev/null)
        total=${#FILES[@]}
        cleaned=0
        skipped=0
        echo -e "\e[38;2;198;160;246m[SCRUBBING FOLDER]\e[0m $TARGET"
        echo -e "\e[38;2;110;115;141mFound $total files\e[0m\n"
        for i in "${!FILES[@]}"; do
            file="${FILES[$i]}"
            base=$(basename "$file")
            printf "  [%3d/%d] %-50s" $((i + 1)) "$total" "${base:0:50}"
            if clean_file "$file" "$mode" > /dev/null 2>&1; then
                printf "\r  \e[32m✔\e[0m [%3d/%d] %s\n" $((i + 1)) "$total" "${base:0:50}"
                ((cleaned++))
            else
                printf "\r  \e[33m⚠\e[0m [%3d/%d] %s  (\e[38;2;147;154;183mformat not supported\e[0m)\n" $((i + 1)) "$total" "${base:0:50}"
                ((skipped++))
            fi
        done
        echo -e "\n\e[32m✔ Done: $cleaned cleaned, $skipped skipped\e[0m"
    else
        clean_file "$TARGET" "$mode"
    fi
    exit 0
fi

options="🧹 Clean File Metadata\n📂 Clean Folder Metadata\n🔍 Inspect File Details\n⚡ Deep Clean File\n📁 Deep Clean Folder\n📦 Install Dependencies\n🚪 Exit"
chosen=$(menu "󰗨 Cleaner" "$options")
[[ -z "$chosen" || "$chosen" == *"Exit"* ]] && exit 0

case "$chosen" in
    *"Clean File"*)
        run_in_term "Metadata Scrub" "
            read -e -p \$'\\e[36mFile path: \\e[0m' target
            target=\"\${target/#\\~/\$HOME}\"
            [[ -z \"\$target\" ]] && exit
            [[ ! -f \"\$target\" ]] && echo -e '\e[31mFile not found.\e[0m' && exit
            bash '$0' --clean-now \"\$target\" 'clean'
        "
        ;;
    *"Clean Folder"*)
        run_in_term "Folder Scrub" "
            read -e -p \$'\\e[36mFolder path: \\e[0m' target
            target=\"\${target/#\\~/\$HOME}\"
            [[ -z \"\$target\" ]] && exit
            [[ ! -d \"\$target\" ]] && echo -e '\e[31mFolder not found.\e[0m' && exit
            bash '$0' --clean-now \"\$target\" 'clean'
        "
        ;;
    *"Inspect"*)
        run_in_term "Metadata Inspection" "
            read -e -p \$'\\e[36mFile path: \\e[0m' target
            target=\"\${target/#\\~/\$HOME}\"
            [[ -z \"\$target\" ]] && exit
            [[ ! -f \"\$target\" ]] && echo -e '\e[31mFile not found.\e[0m' && exit
            bash '$0' --clean-now \"\$target\" 'inspect'
        "
        ;;
    *"Deep Clean File"*)
        run_in_term "Deep Clean" "
            read -e -p \$'\\e[36mFile path: \\e[0m' target
            target=\"\${target/#\\~/\$HOME}\"
            [[ -z \"\$target\" ]] && exit
            [[ ! -f \"\$target\" ]] && echo -e '\e[31mFile not found.\e[0m' && exit
            bash '$0' --clean-now \"\$target\" 'deep'
        "
        ;;
    *"Deep Clean Folder"*)
        run_in_term "Deep Clean Folder" "
            read -e -p \$'\\e[36mFolder path: \\e[0m' target
            target=\"\${target/#\\~/\$HOME}\"
            [[ -z \"\$target\" ]] && exit
            [[ ! -d \"\$target\" ]] && echo -e '\e[31mFolder not found.\e[0m' && exit
            bash '$0' --clean-now \"\$target\" 'deep'
        "
        ;;
    *"Install Dependencies"*)
        run_in_term "Install Tools" "sudo pacman -S --needed --noconfirm mat2 perl-image-exiftool bc"
        ;;
esac
