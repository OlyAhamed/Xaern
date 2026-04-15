#!/usr/bin/env bash
# ==============================================
# Theme Switcher (System UI Only)
# ==============================================

THEMES_DIR="$HOME/.config/themes"
CFG="$HOME/.config"
CURRENT_FILE="$THEMES_DIR/.current"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
log_err()  { echo -e "  ${RED}✗${NC} $1"; }
log_head() { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }

# ── Get current theme ──────────────────────────────────
CURRENT=""
[[ -f "$CURRENT_FILE" ]] && CURRENT=$(cat "$CURRENT_FILE")

# ── Build theme list and launch rofi ──────────────────
OPTIONS=""
for THEME in $(ls "$THEMES_DIR" | grep -v '^\.' | grep -v '\.sh$\|\.rasi$'); do
  if [[ "$THEME" == "$CURRENT" ]]; then
    OPTIONS+="● $THEME\n"
  else
    OPTIONS+="  $THEME\n"
  fi
done

SELECTED=$(echo -e "$OPTIONS" | rofi \
  -dmenu \
  -i \
  -p "" \
  -theme "$THEMES_DIR/theme-switcher.rasi")

[[ -z "$SELECTED" ]] && exit 0

SELECTED=$(echo "$SELECTED" | sed 's/^[●[:space:]]*//')

if [[ ! -d "$THEMES_DIR/$SELECTED" ]]; then
  echo -e "${RED}Error:${NC} Theme '$SELECTED' not found"
  exit 1
fi

HOOK="$THEMES_DIR/$SELECTED"
echo -e "${BOLD}Switching to $SELECTED...${NC}"

# ── Symlink function ───────────────────────────────────
link_hook() {
  local src="$1" dst="$2"
  [[ ! -f "$src" ]] && return
  mkdir -p "$(dirname "$dst")"
  ln -sf "$src" "$dst" && log_ok "$(basename "$dst")" || log_err "Failed → $(basename "$dst")"
}

# ── Link all hooks ─────────────────────────────────────
log_head "Linking hooks"

link_hook "$HOOK/kitty.conf"    "$CFG/kitty/colors/colors.conf"
link_hook "$HOOK/waybar.css"    "$CFG/waybar/colors/colors.css"
link_hook "$HOOK/swaync.css"    "$CFG/swaync/colors/colors.css"
link_hook "$HOOK/swayosd.css"   "$CFG/swayosd/colors/colors.css"
link_hook "$HOOK/colors.rasi"   "$CFG/rofi/colors/colors.rasi"
link_hook "$HOOK/hypr.conf"     "$CFG/hypr/colors/colors.conf"
link_hook "$HOOK/sway.conf"     "$CFG/sway/colors/colors.conf"
link_hook "$HOOK/colors.theme"  "$CFG/btop/colors/colors.theme"
link_hook "$HOOK/colors.json"   "$CFG/pywalfox/colors/colors.json"
link_hook "$HOOK/gtk.css"       "$CFG/gtk-3.0/colors/colors.css"
link_hook "$HOOK/gtk.css"       "$CFG/gtk-4.0/colors/colors.css"

# ── Save current theme ─────────────────────────────────
echo "$SELECTED" > "$CURRENT_FILE"

# ── Icon color map ─────────────────────────────────────
THEME_NAME=$(echo "$SELECTED" | sed 's/\.[^.]*$//')

case "$THEME_NAME" in
  "OsakaJade")      ICON_COL="teal" ;;
  "TokyoNight")     ICON_COL="blue" ;;
  "Catppuccin")     ICON_COL="magenta" ;;
  "Dracula")        ICON_COL="violet" ;;
  "Everforest")     ICON_COL="green" ;;
  "Gruvbox")        ICON_COL="brown" ;;
  "Kanagawa")       ICON_COL="indigo" ;;
  "Material")       ICON_COL="blue" ;;
  "Monochrome")     ICON_COL="grey" ;;
  "Nightfox")       ICON_COL="darkcyan" ;;
  "Nord")           ICON_COL="nordic" ;;
  "OneDark")        ICON_COL="blue" ;;
  "RosePine")       ICON_COL="carmine" ;;
  "SolarizedDark")  ICON_COL="blue" ;;
  "SolarizedLight") ICON_COL="paleorange" ;;
  *)                ICON_COL="blue" ;;
esac

# ── Reload apps ────────────────────────────────────────
log_head "Reloading apps"

# Waybar
pgrep -x waybar    > /dev/null && pkill -SIGUSR2 waybar                 && log_ok "waybar"

# Kitty
pgrep -x kitty     > /dev/null && kill -SIGUSR1 $(pgrep kitty)          && log_ok "kitty"

# Window Managers
pgrep -x sway      > /dev/null && swaymsg reload                        && log_ok "sway"
pgrep -x Hyprland > /dev/null && hyprctl reload                        && log_ok "hyprland"

# Notification Center
pgrep -x swaync    > /dev/null && swaync-client --reload-css            && log_ok "swaync"

# SwayOSD restart (backgrounded)
if pgrep -x swayosd-server > /dev/null; then
  (pkill swayosd-server; sleep 0.3; swayosd-server &) & disown
  log_ok "swayosd (backgrounded)"
fi

# Pywalfox (Firefox)
command -v pywalfox > /dev/null && (pywalfox update &) && log_ok "pywalfox (backgrounded)"

# Btop note
pgrep -x btop > /dev/null && echo -e "  ${YELLOW}~${NC} btop: restart manually to apply"

# ── GTK refresh ────────────────────────────────────────
log_head "GTK"

# Write settings.ini for GTK3 apps
mkdir -p "$CFG/gtk-3.0"
cat > "$CFG/gtk-3.0/settings.ini" << GTKINI
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-application-prefer-dark-theme=1
gtk-font-name=CaskaydiaCove Nerd Font 11
GTKINI

# Set theme and toggle color-scheme to force libadwaita apps to reread
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null
gsettings set org.gnome.desktop.interface color-scheme 'default'     2>/dev/null
sleep 0.05
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null && log_ok "gtk4 refresh"

# Kick portal for sandboxed apps
gdbus call --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.Read \
  "org.gnome.desktop.interface" "color-scheme" > /dev/null 2>&1

log_ok "gtk3 settings.ini updated"

# Restart Nautilus
if pgrep -x nautilus > /dev/null; then
  nautilus -q && sleep 0.1 && nautilus & disown
  log_ok "nautilus restarted"
fi

# ── Icons (backgrounded) ───────────────────────────────
log_head "Icons"

if command -v papirus-folders > /dev/null; then
  # sudo -n ensures it doesn't hang if password is required
  (sudo -n papirus-folders -o -t Papirus-Dark -C "$ICON_COL" > /dev/null 2>&1 &)
  log_ok "icons → $ICON_COL (backgrounded)"
else
  log_err "papirus-folders not installed"
fi

# ── Wallpaper ──────────────────────────────────────────
log_head "Wallpaper"

WALLS_SRC="$HOOK/walls"
WALLS_DST="$CFG/wallpapers"

if [[ -d "$WALLS_SRC" ]]; then
  ln -sfn "$WALLS_SRC" "$WALLS_DST" && log_ok "wallpapers → $WALLS_SRC"
  echo "-1" > "$THEMES_DIR/.wall_index"
  
  # Find random image in the theme folder
  WALL=$(find -L "$WALLS_SRC" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
  
  # Using awww for wallpaper setting
  [[ -n "$WALL" ]] && awww img "$WALL" --transition-type wipe --transition-duration 1 \
    && log_ok "$(basename "$WALL")" || log_err "awww failed"
else
  echo -e "  ${YELLOW}~${NC} No walls/ folder found for $SELECTED"
fi

echo -e "\n${GREEN}${BOLD}Done!${NC} Theme → ${BOLD}$SELECTED${NC}\n"
