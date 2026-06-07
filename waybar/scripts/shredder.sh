#!/usr/bin/env bash
# =============================================================================
# Secure Shredder – Omarchy Terminal Edition
# =============================================================================

menu() {
    local prompt="$1"
    local options="$2"
    echo -e "$options" | omarchy-launch-walker --dmenu -p "$prompt" --width 600 --maxheight 500
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

shred_file() {
    local file="$1"
    local passes="$2"

    [[ ! -f "$file" && ! -L "$file" ]] && return 1

    chmod 644 "$file" 2>/dev/null

    if shred -u -n "$passes" -z "$file" 2>/dev/null; then
        return 0
    fi

    if command -v sudo &>/dev/null; then
        sudo shred -u -n "$passes" -z "$file" 2>/dev/null && return 0
    fi

    if command -v wipe &>/dev/null; then
        wipe -rf "$file" 2>/dev/null && return 0
    fi

    if command -v srm &>/dev/null; then
        srm -z "$file" 2>/dev/null && return 0
    fi

    dd if=/dev/urandom of="$file" bs=4096 count=$(($(stat -c%s "$file" 2>/dev/null || echo 1) / 4096 + 1)) 2>/dev/null
    rm -f "$file" 2>/dev/null
    [[ ! -f "$file" ]] && return 0

    return 1
}

if [[ "$1" == "--shred-now" ]]; then
    MODE=$2
    TARGET=$3
    PASSES=$4

    echo -e "\e[38;2;237;135;150m⚠️  DESTRUCTION PROTOCOL ACTIVE\e[0m"
    echo -e "\e[38;2;133;171;188mTarget:\e[0m $TARGET"
    echo -e "\e[38;2;133;171;188mSize:\e[0m $(du -h --apparent-size "$TARGET" 2>/dev/null | cut -f1)"
    echo -e "\e[38;2;133;171;188mPasses:\e[0m $PASSES + zero-fill\n"

    read -p "Type 'yes' to confirm permanent destruction: " confirm
    if [[ "$confirm" == "yes" ]]; then
        if [[ -d "$TARGET" ]]; then
            mapfile -t FILES < <(find "$TARGET" -type f 2>/dev/null)
            total=${#FILES[@]}
            shredded=0
            failed=0
            echo -e "\e[38;2;198;160;246m[SHREDDING FOLDER]\e[0m $TARGET"
            echo -e "\e[38;2;110;115;141mFound $total files\e[0m\n"
            for i in "${!FILES[@]}"; do
                file="${FILES[$i]}"
                base=$(basename "$file")
                printf "  [%3d/%d] %s" $((i + 1)) "$total" "${base:0:55}"
                if shred_file "$file" "$PASSES"; then
                    printf "\r  \e[32m✔\e[0m [%3d/%d] %s\n" $((i + 1)) "$total" "${base:0:55}"
                    ((shredded++))
                else
                    printf "\r  \e[31m✘\e[0m [%3d/%d] %s\n" $((i + 1)) "$total" "${base:0:55}"
                    ((failed++))
                fi
            done
            find "$TARGET" -depth -type d -exec rmdir {} \; 2>/dev/null
            rm -rf "$TARGET" 2>/dev/null
            echo -e "\n\e[32m✔ Done: $shredded shredded, $failed failed\e[0m"
        else
            if shred_file "$TARGET" "$PASSES"; then
                echo -e "\n\n\e[38;2;166;218;149m✔ Data has been physically erased.\e[0m"
            else
                echo -e "\n\n\e[31m✘ Failed to erase.\e[0m"
            fi
        fi
    else
        echo -e "\n\e[31mOperation cancelled.\e[0m"
    fi
    exit 0
fi

if [[ "$1" == "--dry-run" ]]; then
    TARGET="$2"
    echo -e "\e[38;2;198;160;246m[DRY RUN]\e[0m $TARGET\n"
    if [[ -d "$TARGET" ]]; then
        mapfile -t FILES < <(find "$TARGET" -type f 2>/dev/null)
        total=${#FILES[@]}
        echo -e "\e[38;2;110;115;141mWould shred $total files\e[0m"
        echo -e "\e[38;2;110;115;141mTotal size:\e[0m $(du -sh "$TARGET" 2>/dev/null | cut -f1)"
        echo -e "\e[38;2;110;115;141mPasses:\e[0m 3 + zero-fill\n"
        for file in "${FILES[@]}"; do
            echo -e "  \e[38;2;147;154;183m$(basename "$file")\e[0m  ($(du -h --apparent-size "$file" 2>/dev/null | cut -f1))"
        done
    else
        echo -e "\e[38;2;110;115;141mFile:\e[0m $(basename "$TARGET")"
        echo -e "\e[38;2;110;115;141mSize:\e[0m $(du -h --apparent-size "$TARGET" 2>/dev/null | cut -f1)"
        echo -e "\e[38;2;110;115;141mPasses:\e[0m 3 + zero-fill"
    fi
    echo -e "\n\e[38;2;147;154;183mNo files will be harmed.\e[0m"
    exit 0
fi

options="󰈔 Shred File\n󱪓 Shred Folder\n󰃢 Empty Trash (Secure)\n󰛑 Dry Run Simulation\n🚪 Exit"
chosen=$(menu "󰆴 Shredder" "$options")
[[ -z "$chosen" || "$chosen" == *"Exit"* ]] && exit 0

case "$chosen" in
    *"Shred File"*)
        run_in_term "Secure Shredder" "
            read -e -p \$'\\e[36mFile path: \\e[0m' target
            target=\"\${target/#\\~/\$HOME}\"
            [[ -z \"\$target\" ]] && exit
            [[ ! -f \"\$target\" ]] && echo -e '\e[31mFile not found.\e[0m' && exit
            read -e -p \$'\\e[36mPasses (1-35, default 3): \\e[0m' passes
            passes=\"\${passes:-3}\"
            bash '$0' --shred-now 'Shred File' \"\$target\" \"\$passes\"
        "
        ;;
    *"Shred Folder"*)
        run_in_term "Folder Shredder" "
            read -e -p \$'\\e[36mFolder path: \\e[0m' target
            target=\"\${target/#\\~/\$HOME}\"
            [[ -z \"\$target\" ]] && exit
            [[ ! -d \"\$target\" ]] && echo -e '\e[31mFolder not found.\e[0m' && exit
            read -e -p \$'\\e[36mPasses (1-35, default 3): \\e[0m' passes
            passes=\"\${passes:-3}\"
            bash '$0' --shred-now 'Shred Folder' \"\$target\" \"\$passes\"
        "
        ;;
    *"Empty Trash"*)
        run_in_term "Empty Trash" "
            target=\"\$HOME/.local/share/Trash/files\"
            [[ ! -d \"\$target\" ]] && echo -e '\e[33mTrash is already empty.\e[0m' && exit
            read -e -p \$'\\e[36mPasses (1-35, default 3): \\e[0m' passes
            passes=\"\${passes:-3}\"
            bash '$0' --shred-now 'Empty Trash' \"\$target\" \"\$passes\"
        "
        ;;
    *"Dry Run"*)
        run_in_term "Shred Simulation" "
            read -e -p \$'\\e[36mFile/folder path: \\e[0m' target
            target=\"\${target/#\\~/\$HOME}\"
            [[ -z \"\$target\" ]] && exit
            [[ ! -e \"\$target\" ]] && echo -e '\e[31mPath not found.\e[0m' && exit
            bash '$0' --dry-run \"\$target\"
        "
        ;;
esac
