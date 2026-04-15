#!/usr/bin/env bash
# ==============================================
# Wallpaper Cycler - Sequential
# Cycles through walls in order, one per keypress
# ==============================================

WALLS_DIR="$HOME/.config/wallpapers"
STATE_FILE="$HOME/.config/themes/.wall_index"

if [[ ! -d "$WALLS_DIR" ]]; then
  echo "No wallpapers directory found at $WALLS_DIR"
  exit 1
fi

# Build sorted list of wallpapers
mapfile -t WALLS < <(find -L "$WALLS_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort)

COUNT=${#WALLS[@]}
[[ $COUNT -eq 0 ]] && echo "No wallpapers found in $WALLS_DIR" && exit 1

# Read current index, default to -1 so first press shows index 0
INDEX=-1
[[ -f "$STATE_FILE" ]] && INDEX=$(cat "$STATE_FILE")

# Advance to next
INDEX=$(( (INDEX + 1) % COUNT ))

# Save index
echo "$INDEX" > "$STATE_FILE"

# Set wallpaper
awww img "${WALLS[$INDEX]}" --transition-type wipe --transition-duration 1
