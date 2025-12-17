#!/usr/bin/env bash

set -euo pipefail

# ========= CONFIG =========
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_PUB_KEY="$SSH_KEY.pub"
EMAIL_DEFAULT="$(git config --global user.email || true)"
MAX_RETRIES=3

# ========= UI =========

title() {
  gum style \
    --border double \
    --align center \
    --padding "1 4" \
    --bold \
    "🔐 Configuración SSH para GitHub"
}

error_msg() {
  gum style --foreground 196 "❌ $1"
}

success_msg() {
  gum style --foreground 42 "✅ $1"
}

info_msg() {
  gum style --foreground 39 "ℹ️  $1"
}

# ========= LÓGICA =========

run_with_retry() {
  local description="$1"
  shift
  local cmd=("$@")
  local attempt=1

  while true; do
    info_msg "$description"

    if "${cmd[@]}"; then
      success_msg "Paso completado"
      return 0
    fi

    error_msg "Falló el intento $attempt de $MAX_RETRIES"

    if ((attempt >= MAX_RETRIES)); then
      return 1
    fi

    gum confirm "¿Deseas reintentar?" || return 1
    ((attempt++))
  done
}

ensure_ssh_agent() {
  eval "$(ssh-agent -s)" >/dev/null
}

generate_key() {
  [[ -f "$SSH_KEY" ]] && return 0

  local email
  email=$(gum input \
    --value "$EMAIL_DEFAULT" \
    --placeholder "Email para la clave SSH")

  ssh-keygen -t ed25519 -C "$email" -f "$SSH_KEY" -N ""
}

add_key_to_agent() {
  ensure_ssh_agent
  ssh-add "$SSH_KEY"
}

show_public_key() {
  gum style --bold "📋 Copia esta clave y agrégala en GitHub:"
  gum style --border rounded --padding "1 2" "$(cat "$SSH_PUB_KEY")"
}

wait_for_github() {
  gum style \
    "👉 Ve a GitHub → Settings → SSH and GPG keys → New SSH key"
  gum confirm "¿Ya agregaste la clave en GitHub?"
}

test_connection() {
  local output

  output="$(ssh -T git@github.com 2>&1 || true)"

  echo "$output" | grep -q "successfully authenticated"
}

# ========= FLUJO =========

clear
title

if [[ -f "$SSH_KEY" ]]; then
  info_msg "Ya existe una clave SSH en $SSH_KEY"
else
  run_with_retry "Generando clave SSH..." generate_key || exit 1
fi

run_with_retry "Añadiendo clave al ssh-agent..." add_key_to_agent || exit 1

show_public_key

run_with_retry "Esperando confirmación del usuario..." wait_for_github || exit 1

run_with_retry "Probando conexión con GitHub..." test_connection || {
  error_msg "No se pudo conectar con GitHub vía SSH"
  exit 1
}

success_msg "🎉 SSH configurado correctamente con GitHub"
