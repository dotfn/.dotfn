#!/usr/bin/env bash
set -euo pipefail

# ========= CONFIG =========
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
SSH_PUB_KEY="$SSH_KEY.pub"
SSH_CONFIG="$SSH_DIR/config"
MAX_RETRIES=3

# ========= DEPENDENCIAS =========
check_dependencies() {
  # Verificar Homebrew
  if ! command -v brew &>/dev/null; then
    echo "⚠️  Homebrew no está instalado. Es necesario para instalar gum."
    echo "Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Verificar gum
  if ! command -v gum &>/dev/null; then
    echo "📦 Instalando gum..."
    brew install gum
  fi

  # Verificar git
  if ! command -v git &>/dev/null; then
    gum style --foreground 196 "❌ Git no está instalado. Instalando via Homebrew..."
    brew install git
  fi
}

# ========= UI =========
title() {
  clear
  gum style \
    --border double \
    --align center \
    --padding "1 4" \
    --bold \
    --foreground 212 \
    "🍎 Configuración SSH + Git para GitHub"
  echo ""
}

error_msg()   { gum style --foreground 196 "❌  $1"; }
success_msg() { gum style --foreground 82  "✅  $1"; }
info_msg()    { gum style --foreground 39  "ℹ️   $1"; }
warn_msg()    { gum style --foreground 214 "⚠️   $1"; }
section()     { echo ""; gum style --bold --foreground 212 "── $1 ──"; echo ""; }

# ========= RETRY =========
run_with_retry() {
  local description="$1"
  shift
  local cmd=("$@")
  local attempt=1

  while true; do
    info_msg "$description"
    if "${cmd[@]}"; then
      success_msg "Completado"
      return 0
    fi
    error_msg "Falló el intento $attempt de $MAX_RETRIES"
    ((attempt >= MAX_RETRIES)) && return 1
    gum confirm "¿Reintentar?" || return 1
    ((attempt++))
  done
}

# ========= GIT CONFIG =========
get_git_config() {
  git config --global "$1" 2>/dev/null || true
}

configure_git() {
  section "Configuración de Git"

  local current_name current_email current_editor
  current_name="$(get_git_config user.name)"
  current_email="$(get_git_config user.email)"
  current_editor="$(get_git_config core.editor)"

  # Mostrar estado actual
  if [[ -n "$current_name" || -n "$current_email" ]]; then
    gum style --bold "Configuración actual detectada:"
    [[ -n "$current_name" ]]   && info_msg "Nombre : $current_name"
    [[ -n "$current_email" ]]  && info_msg "Email  : $current_email"
    [[ -n "$current_editor" ]] && info_msg "Editor : $current_editor"
    echo ""

    if ! gum confirm "¿Deseas actualizar la configuración de Git?"; then
      success_msg "Configuración de Git sin cambios"
      return 0
    fi
  fi

  # Nombre
  local name
  name=$(gum input \
    --value "$current_name" \
    --placeholder "Tu nombre completo" \
    --prompt "👤 Nombre: ")
  [[ -z "$name" ]] && { error_msg "El nombre no puede estar vacío"; return 1; }
  git config --global user.name "$name"

  # Email
  local email
  email=$(gum input \
    --value "$current_email" \
    --placeholder "tu@email.com" \
    --prompt "📧 Email: ")
  [[ -z "$email" ]] && { error_msg "El email no puede estar vacío"; return 1; }
  git config --global user.email "$email"

  # Editor preferido
  local editor
  editor=$(gum choose --header "📝 Editor predeterminado para commits:" \
    "vim" "nano" "code --wait" "subl -n -w" "none (mantener actual)")
  [[ "$editor" != "none (mantener actual)" ]] && git config --global core.editor "$editor"

  # Configuraciones recomendadas adicionales
  if gum confirm "¿Aplicar configuraciones recomendadas? (pull.rebase, init.defaultBranch=main, etc.)"; then
    git config --global pull.rebase false
    git config --global init.defaultBranch main
    git config --global core.autocrlf input
    git config --global color.ui auto
    git config --global push.autoSetupRemote true
    success_msg "Configuraciones adicionales aplicadas"
  fi

  success_msg "Git configurado: $name <$email>"
}

# ========= SSH =========
ensure_ssh_dir() {
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
}

list_existing_keys() {
  # Lista todas las claves ed25519/rsa en ~/.ssh (sin .pub)
  find "$SSH_DIR" -maxdepth 1 -type f \
    ! -name "*.pub" ! -name "config" ! -name "known_hosts" ! -name "authorized_keys" \
    2>/dev/null | sort
}

select_or_create_key() {
  section "Clave SSH"
  ensure_ssh_dir

  local existing_keys=()
  while IFS= read -r k; do
    [[ -n "$k" ]] && existing_keys+=("$k")
  done < <(list_existing_keys)

  if ((${#existing_keys[@]} > 0)); then
    gum style --bold "Se encontraron claves SSH existentes:"
    for k in "${existing_keys[@]}"; do
      local fp
      fp=$(ssh-keygen -lf "$k" 2>/dev/null || echo "no se pudo leer")
      info_msg "$(basename "$k")  →  $fp"
    done
    echo ""

    local action
    action=$(gum choose --header "¿Qué deseas hacer?" \
      "Usar una clave existente" \
      "Crear una nueva clave" \
      "Salir")

    case "$action" in
      "Usar una clave existente")
        # Construir opciones de selección
        local key_names=()
        for k in "${existing_keys[@]}"; do key_names+=("$(basename "$k")"); done
        local chosen_name
        chosen_name=$(gum choose --header "Selecciona la clave a usar:" "${key_names[@]}")
        SSH_KEY="$SSH_DIR/$chosen_name"
        SSH_PUB_KEY="$SSH_KEY.pub"

        if [[ ! -f "$SSH_PUB_KEY" ]]; then
          error_msg "No se encontró la clave pública para $chosen_name"
          return 1
        fi
        success_msg "Usando clave: $SSH_KEY"
        ;;
      "Crear una nueva clave")
        generate_key
        ;;
      "Salir")
        exit 0
        ;;
    esac
  else
    info_msg "No se encontraron claves SSH. Se creará una nueva."
    generate_key
  fi
}

generate_key() {
  local email
  email=$(git config --global user.email 2>/dev/null || true)
  email=$(gum input \
    --value "$email" \
    --placeholder "tu@email.com" \
    --prompt "📧 Email para la clave SSH: ")
  [[ -z "$email" ]] && { error_msg "El email no puede estar vacío"; return 1; }

  # Nombre del archivo de clave (permite múltiples cuentas)
  local default_name="id_ed25519"
  local key_name
  key_name=$(gum input \
    --value "$default_name" \
    --placeholder "id_ed25519" \
    --prompt "🔑 Nombre del archivo de clave: ")
  [[ -z "$key_name" ]] && key_name="$default_name"

  SSH_KEY="$SSH_DIR/$key_name"
  SSH_PUB_KEY="$SSH_KEY.pub"

  if [[ -f "$SSH_KEY" ]]; then
    warn_msg "Ya existe una clave con ese nombre: $SSH_KEY"
    if ! gum confirm "¿Sobreescribir la clave existente?"; then
      info_msg "Usando clave existente"
      return 0
    fi
    rm -f "$SSH_KEY" "$SSH_PUB_KEY"
  fi

  # Passphrase opcional
  local passphrase=""
  if gum confirm "¿Agregar passphrase a la clave? (recomendado para mayor seguridad)"; then
    passphrase=$(gum input --password --prompt "🔒 Passphrase: ")
  fi

  ssh-keygen -t ed25519 -C "$email" -f "$SSH_KEY" -N "$passphrase"
  chmod 600 "$SSH_KEY"
  chmod 644 "$SSH_PUB_KEY"
  success_msg "Clave generada: $SSH_KEY"
}

# ========= SSH AGENT (macOS Keychain) =========
setup_ssh_agent() {
  section "SSH Agent + Keychain"

  # Iniciar ssh-agent si no está corriendo
  if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    eval "$(ssh-agent -s)" >/dev/null
  fi

  # Detectar versión de macOS para usar el flag correcto
  local macos_version
  macos_version=$(sw_vers -productVersion | cut -d. -f1)

  if [[ "$macos_version" -ge 12 ]]; then
    # Monterey y superior: --apple-use-keychain
    ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || \
    ssh-add "$SSH_KEY"
  else
    # Versiones anteriores: -K
    ssh-add -K "$SSH_KEY" 2>/dev/null || \
    ssh-add "$SSH_KEY"
  fi

  success_msg "Clave añadida al agente SSH"
}

# ========= SSH CONFIG =========
update_ssh_config() {
  section "Configuración ~/.ssh/config"

  ensure_ssh_dir
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"

  # Verificar si ya existe un bloque para github.com con esta clave
  if grep -q "IdentityFile $SSH_KEY" "$SSH_CONFIG" 2>/dev/null; then
    info_msg "Ya existe una entrada en ~/.ssh/config para esta clave"
    return 0
  fi

  local hostname_alias="github.com"

  # Si ya existe un bloque github.com, usar un alias
  if grep -q "^Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    warn_msg "Ya existe un Host github.com en tu ~/.ssh/config"
    hostname_alias=$(gum input \
      --value "github-personal" \
      --placeholder "github-personal" \
      --prompt "🏷️  Alias para este host (para múltiples cuentas): ")
    [[ -z "$hostname_alias" ]] && hostname_alias="github-$(date +%s)"
    info_msg "Usarás: git@${hostname_alias}:usuario/repo.git para clonar con esta clave"
  fi

  # Detectar versión para UseKeychain
  local macos_version
  macos_version=$(sw_vers -productVersion | cut -d. -f1)
  local keychain_line=""
  [[ "$macos_version" -ge 12 ]] && keychain_line="  UseKeychain yes"

  cat >> "$SSH_CONFIG" <<EOF

Host $hostname_alias
  HostName github.com
  User git
  IdentityFile $SSH_KEY
  AddKeysToAgent yes
$keychain_line
EOF

  success_msg "~/.ssh/config actualizado (Host: $hostname_alias)"
}

# ========= MOSTRAR CLAVE PÚBLICA =========
show_and_copy_public_key() {
  section "Clave Pública"

  local pub_key
  pub_key=$(cat "$SSH_PUB_KEY")

  gum style --bold "📋 Tu clave pública SSH:"
  gum style \
    --border rounded \
    --padding "1 2" \
    --foreground 82 \
    "$pub_key"
  echo ""

  # Copiar al portapapeles (pbcopy es nativo en macOS)
  if echo "$pub_key" | pbcopy 2>/dev/null; then
    success_msg "Clave copiada al portapapeles ✂️"
  else
    warn_msg "No se pudo copiar automáticamente. Cópiala manualmente."
  fi

  # Opción de abrir GitHub directamente
  if gum confirm "¿Abrir GitHub en Safari/Chrome para agregar la clave?"; then
    open "https://github.com/settings/ssh/new"
  fi
}

# ========= ESPERAR CONFIRMACIÓN =========
wait_for_github() {
  gum style --bold "👉 Pasos en GitHub:"
  gum style "   1. Settings → SSH and GPG keys → New SSH key"
  gum style "   2. Title: cualquier nombre descriptivo (ej: MacBook Pro 2024)"
  gum style "   3. Key type: Authentication Key"
  gum style "   4. Pega la clave y haz clic en 'Add SSH key'"
  echo ""
  gum confirm "¿Ya agregaste la clave en GitHub?"
}

# ========= TEST CONEXIÓN =========
test_connection() {
  local output
  output="$(ssh -T git@github.com 2>&1 || true)"
  if echo "$output" | grep -q "successfully authenticated"; then
    local github_user
    github_user=$(echo "$output" | grep -o "Hi [^!]*" | cut -d' ' -f2 || echo "desconocido")
    success_msg "Autenticado como: $github_user"
    return 0
  fi
  error_msg "Respuesta de GitHub: $output"
  return 1
}

# ========= RESUMEN FINAL =========
show_summary() {
  section "Resumen"

  gum style --bold "Configuración completada:"
  echo ""
  gum style "  👤 Git nombre : $(git config --global user.name)"
  gum style "  📧 Git email  : $(git config --global user.email)"
  gum style "  🔑 Clave SSH  : $SSH_KEY"
  gum style "  📋 Config SSH : $SSH_CONFIG"
  echo ""

  gum style --bold "Para clonar un repo usando esta clave:"
  gum style --foreground 82 "  git clone git@github.com:usuario/repositorio.git"
  echo ""

  success_msg "🎉 ¡SSH configurado correctamente con GitHub!"
}

# ========= MAIN =========
check_dependencies
title

# ── Git ──
if gum confirm "¿Configurar nombre/email de Git?"; then
  configure_git || { error_msg "Error configurando Git"; exit 1; }
fi

# ── SSH Key ──
select_or_create_key || { error_msg "Error con la clave SSH"; exit 1; }

# ── Agent ──
run_with_retry "Añadiendo clave al ssh-agent..." setup_ssh_agent || {
  error_msg "No se pudo añadir la clave al agente"
  exit 1
}

# ── SSH Config ──
update_ssh_config

# ── Clave pública ──
show_and_copy_public_key

# ── Esperar GitHub ──
run_with_retry "Esperando que agregues la clave en GitHub..." wait_for_github || {
  warn_msg "Puedes correr el script de nuevo cuando hayas agregado la clave"
  exit 0
}

# ── Test ──
run_with_retry "Probando conexión SSH con GitHub..." test_connection || {
  error_msg "No se pudo conectar. Verificá que la clave esté bien pegada en GitHub."
  info_msg "Podés testear manualmente con: ssh -T git@github.com"
  exit 1
}

show_summary