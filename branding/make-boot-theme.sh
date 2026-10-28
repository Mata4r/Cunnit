#!/usr/bin/env bash
# Brand the live-build boot menus (ISOLINUX for BIOS, GRUB for UEFI) as Cunnit.
# Usage: make-boot-theme.sh <live-build config dir> <logo.txt>
set -euo pipefail
CFG=$1
LOGO_FILE=$2
BL=$CFG/bootloaders

GREEN='#90EE90'
DIM='#5E9E5E'
BG='#0B0F0B'
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf
TAGLINE='BOOT MENU  -  Debian based'
IM=$(command -v magick || command -v convert)
# ImageMagick reads "\\" as a literal backslash and trims leading plain
# spaces, so use non-breaking spaces (same width in a monospace font).
LOGO=$(sed -e 's/\\/\\\\/g' -e 's/ /\xc2\xa0/g' "$LOGO_FILE")
COLS=$(awk '{ if (length($0) > m) m = length($0) } END { print m }' "$LOGO_FILE")
ROWS=$(wc -l < "$LOGO_FILE")

# render <out.png> <width> <height> <pointsize> <top>
render() {
  local out=$1 w=$2 h=$3 ps=$4 y=$5
  local lh=$(( ps * 117 / 100 ))            # DejaVu Sans Mono line height
  local tw=$(( ps * COLS * 602 / 1000 ))    # and advance width
  local x=$(( (w - tw) / 2 ))
  local bar=$(( y + ROWS * lh + ps / 2 ))
  local thick=$(( ps / 2 + 2 ))
  "$IM" -size "${w}x${h}" "xc:$BG" -font "$FONT" -gravity northwest \
    -fill "$GREEN" -pointsize "$ps" -annotate "+$x+$y" "$LOGO" \
    -draw "rectangle $x,$bar $(( x + tw )),$(( bar + thick ))" \
    -gravity north -fill "$DIM" -pointsize $(( ps * 7 / 10 )) \
    -annotate "+0+$(( bar + thick + ps ))" "$TAGLINE" \
    "PNG24:$out"
}

# --- ISOLINUX (BIOS) -----------------------------------------------------
ISO=$BL/isolinux
render "$ISO/splash.png" 640 480 12 24
cat > "$ISO/stdmenu.cfg" <<'CFG'
menu background splash.png
menu color screen       * #00000000 #00000000 none
menu color border       * #00000000 #00000000 none
menu color title        * #ff90ee90 #00000000 none
menu color sel          * #ff0b0f0b #ff90ee90 none
menu color unsel        * #ff90ee90 #00000000 none
menu color hotsel       * #ff0b0f0b #ff90ee90 none
menu color hotkey       * #ffffffff #00000000 none
menu color tabmsg       * #ff5e9e5e #00000000 none
menu color timeout_msg  * #ff5e9e5e #00000000 none
menu color timeout      * #ff90ee90 #00000000 none
menu color help         * #ff5e9e5e #00000000 none
menu vshift 12
menu rows 8
menu width 60
menu margin 10
menu helpmsgrow 22
menu timeoutrow 26
menu tabmsgrow 28
CFG
sed -i 's/^\s*menu title .*/menu title Cunnit Boot Menu/' "$ISO"/*.cfg
sed -i 's/^\s*timeout 0\s*$/timeout 50/' "$ISO"/isolinux.cfg

# --- GRUB (UEFI) ---------------------------------------------------------
GRUB=$BL/grub-pc
THEME=$GRUB/live-theme
mkdir -p "$THEME"
render "$THEME/cunnit.png" 1024 768 20 50
cp "$THEME/cunnit.png" "$GRUB/splash.png"
for p in c n s e w nw ne sw se; do
  "$IM" -size 8x8 "xc:$GREEN" "PNG24:$THEME/select_$p.png"
done
cat > "$THEME/theme.txt" <<'THEME'
title-text: ""
desktop-image: "cunnit.png"
desktop-color: "#0B0F0B"

+ boot_menu {
  left = 22%
  width = 56%
  top = 44%
  height = 38%
  item_color = "#90EE90"
  selected_item_color = "#0B0F0B"
  selected_item_pixmap_style = "select_*.png"
  item_height = 26
  item_padding = 10
  item_spacing = 6
}

+ label {
  id = "__timeout__"
  top = 86%
  left = 0
  width = 100%
  align = "center"
  color = "#90EE90"
  text = "Booting Cunnit in %d seconds"
}

+ label {
  top = 92%
  left = 0
  width = 100%
  align = "center"
  color = "#5E9E5E"
  text = "Enter: boot    e: edit entry    c: GRUB console"
}
THEME
sed -i 's/set gfxmode=800x600/set gfxmode=1024x768,800x600/' "$GRUB/config.cfg"
cat >> "$GRUB/config.cfg" <<'CFG'
set timeout=5
set theme=/boot/grub/live-theme/theme.txt
export theme
CFG

# --- Entry names, both menus ---------------------------------------------
find "$BL" \( -name '*.cfg' -o -name '*.cfg.in' \) -exec sed -i \
  -e 's/Live system/Cunnit Live/g' \
  -e 's/Debian GNU\/Linux/Cunnit/g' {} +
