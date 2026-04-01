#!/bin/bash

# ==========================================================
# 💿 ISO BURNER TUI — progreso REAL con pv
# ==========================================================

# --- CONFIGURACIÓN ---
DIRECTORIOS=("$HOME/Downloads/Isos" "$HOME/Descargas" ".")

# ----------------------------------------------------------
# 1. BUSCAR ISOs
# ----------------------------------------------------------
ISOS=$(find "${DIRECTORIOS[@]}" -maxdepth 1 -name "*.iso" 2>/dev/null)

if [ -z "$ISOS" ]; then
    gum style --foreground 196 "❌ No se encontraron archivos .iso."
    exit 1
fi

# ----------------------------------------------------------
# 2. SELECCIONAR ISO
# ----------------------------------------------------------
SELECTED_ISO=$(echo "$ISOS" | gum choose --header "Selecciona la ISO:" --height 10)
[ -z "$SELECTED_ISO" ] && exit 1

# ----------------------------------------------------------
# 3. SELECCIONAR DISPOSITIVO
# ----------------------------------------------------------
DEVICE_LIST=$(lsblk -dno NAME,SIZE,MODEL,TYPE | grep -E "usb|sd" \
    | awk '{print $1 " - " $2 " (" $3 ")"}')

if [ -z "$DEVICE_LIST" ]; then
    gum style --foreground 196 "❌ No se detectaron dispositivos USB/SD."
    exit 1
fi

SELECTED_DEV=$(echo "$DEVICE_LIST" | gum choose --header "Selecciona destino:")
[ -z "$SELECTED_DEV" ] && exit 1

DEV_NAME=$(echo "$SELECTED_DEV" | cut -d' ' -f1)
DEV_PATH="/dev/$DEV_NAME"

# ----------------------------------------------------------
# 4. CONFIRMACIÓN
# ----------------------------------------------------------
gum style --border normal --margin 1 --padding 1 --border-foreground 212 \
    "ISO: $SELECTED_ISO" \
    "DESTINO: $DEV_PATH"

gum confirm "⚠️ Se borrarán TODOS los datos de $DEV_PATH. ¿Continuar?" --default=false || exit 0

# ----------------------------------------------------------
# 5. GRABACIÓN CON PROGRESO REAL
# ----------------------------------------------------------
ISO_SIZE=$(stat -c%s "$SELECTED_ISO")

echo
echo "Grabando ISO..."
echo

pv -s "$ISO_SIZE" "$SELECTED_ISO" | sudo dd of="$DEV_PATH" bs=4M oflag=sync status=none

sudo eject "$DEV_PATH"

# ----------------------------------------------------------
# 6. FIN
# ----------------------------------------------------------
gum style --foreground 82 --border double --align center --width 40 \
    "✅ ¡Listo!" \
    "La ISO se grabó correctamente."t
