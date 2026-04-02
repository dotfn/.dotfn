#!/usr/bin/env bash

set -e

# ─────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────
log() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

warn() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}

error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
  exit 1
}

run() {
  "$@"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

dir_exists() {
  [ -d "$1" ]
}

# ─────────────────────────────────────────────────────────
# Downloader
# ─────────────────────────────────────────────────────────
download() {
  if command_exists curl; then
    curl -fsSL "$1"
  elif command_exists wget; then
    wget -qO- "$1"
  else
    error "Necesitás curl o wget"
  fi
}

# ─────────────────────────────────────────────────────────
# Git clone seguro (idempotente)
# ─────────────────────────────────────────────────────────
clone_if_missing() {
  local repo="$1"
  local dest="$2"

  if dir_exists "$dest"; then
    warn "Ya existe: $dest (skip)"
  else
    log "Clonando $(basename "$repo")..."
    run git clone "$repo" "$dest"
  fi
}

# ─────────────────────────────────────────────────────────
# Oh My Zsh
# ─────────────────────────────────────────────────────────
install_ohmyzsh() {
  if dir_exists "$HOME/.oh-my-zsh"; then
    warn "Oh My Zsh ya está instalado"
  else
    log "Instalando Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      run sh -c "$(download https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

# ─────────────────────────────────────────────────────────
# Plugins
# ─────────────────────────────────────────────────────────
install_plugins() {
  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  log "Instalando plugins..."

  clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

  clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

  clone_if_missing https://github.com/zsh-users/zsh-completions \
    "$ZSH_CUSTOM/plugins/zsh-completions"

  clone_if_missing https://github.com/zsh-users/zsh-history-substring-search \
    "$ZSH_CUSTOM/plugins/zsh-history-substring-search"

  clone_if_missing https://github.com/Aloxaf/fzf-tab \
    "$ZSH_CUSTOM/plugins/fzf-tab"
}

# ─────────────────────────────────────────────────────────
# Checks previos (dependencias)
# ─────────────────────────────────────────────────────────
check_requirements() {
  log "Chequeando dependencias..."

  command_exists git || error "git no está instalado"
  command_exists zsh || warn "zsh no está instalado (recomendado)"
}

# ─────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────
main() {
  check_requirements
  install_ohmyzsh
  install_plugins

  log "Setup completo 🚀"
}

main