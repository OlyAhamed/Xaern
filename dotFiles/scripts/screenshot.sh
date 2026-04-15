#!/bin/bash
mkdir -p "$HOME/Pictures/Screenshots"

OPTIONS=("󰹑  Capture Desktop" "󰒅  Capture Area")
SELECTED=0
TOTAL=${#OPTIONS[@]}

tput civis
cleanup() { tput cnorm; }
trap cleanup EXIT

HIDE_TERM() {
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        hyprctl dispatch movetoworkspacesilent special
    elif [[ "${XDG_CURRENT_DESKTOP,,}" == "sway" ]]; then
        swaymsg move scratchpad
    fi
}

SHOW_TERM() {
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        hyprctl dispatch movetoworkspace e+0
    elif [[ "${XDG_CURRENT_DESKTOP,,}" == "sway" ]]; then
        swaymsg scratchpad show
    fi
}

draw_menu() {
    clear
    echo -e "\n╭───────────────────────────────╮"
    printf  "│       Screenshot Tool         │\n"
    echo    "╰───────────────────────────────╯"
    echo    "╭─  Options  ───────────────────╮"
    echo    "│                               │"
    for i in "${!OPTIONS[@]}"; do
        if [ $i -eq $SELECTED ]; then
            printf "│   \033[1;34m▶ %-29s\033[0m│\n" "${OPTIONS[$i]}"
        else
            printf "│    %-30s│\n" "${OPTIONS[$i]}"
        fi
    done
    echo    "│                               │"
    echo    "╰───────────────────────────────╯"
}

take_ss() {
    local mode=$1
    local filename="$HOME/Pictures/Screenshots/Screenshot_$(date +%Y%m%d_%H%M%S).png"

    if [ "$mode" == "area" ]; then
        # Hide terminal FIRST so it's gone before slurp overlay appears
        HIDE_TERM
        sleep 0.2

        local geom
        geom=$(slurp 2>/dev/null)

        if [ -z "$geom" ]; then
            # User cancelled — bring terminal back and return to menu
            SHOW_TERM
            return
        fi

        sleep 0.1
        grim -g "$geom" "$filename"
    else
        HIDE_TERM
        sleep 0.3
        grim "$filename"
    fi

    nohup canberra-gtk-play -i camera-shutter > /dev/null 2>&1 &
    wl-copy < "$filename"
    notify-send -u low -i camera-photo "Screenshot Captured" "Saved to Pictures & Clipboard"

    exit 0
}

while true; do
    draw_menu
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key
        case $key in
            '[A') ((SELECTED--)); [ $SELECTED -lt 0 ] && SELECTED=$((TOTAL-1)) ;;
            '[B') ((SELECTED++)); [ $SELECTED -ge $TOTAL ] && SELECTED=0 ;;
            '')   exit 0 ;;
        esac
    else
        case $key in
            k|K) ((SELECTED--)); [ $SELECTED -lt 0 ] && SELECTED=$((TOTAL-1)) ;;
            j|J) ((SELECTED++)); [ $SELECTED -ge $TOTAL ] && SELECTED=0 ;;
            q|Q) exit 0 ;;
            '')
                case "${OPTIONS[$SELECTED]}" in
                    *"Desktop") take_ss "desktop" ;;
                    *"Area")    take_ss "area"    ;;
                esac
                ;;
        esac
    fi
done
