#!/bin/bash

#############################
# FUNCIONES AUXILIARES
#############################

# Mostrar mensajes informativos
log() {
  echo -e "\e[1;34m[INFO]\e[0m $1"
}

# Ejecutar comando y verificar errores
run() {
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    echo -e "\e[1;31m[ERROR]\e[0m Comando falló: $*"
    exit $status
  fi
}

#############################
# PACMAN
#############################
configure_pacman() {
  log "Configurando pacman..."
  PACMAN_CONF="/etc/pacman.conf"

  if ! grep -qE '^[[:space:]]*Color' "$PACMAN_CONF"; then
    run sudo sed -i 's/#Color/Color/' "$PACMAN_CONF"
  fi

  if ! grep -qE '^ParallelDownloads\s*=\s*20' "$PACMAN_CONF"; then
    run sudo sed -i 's/^ParallelDownloads\s*=\s*[0-9]\+/ParallelDownloads = 20/' "$PACMAN_CONF"
  fi

  if ! grep -q 'ILoveCandy' "$PACMAN_CONF"; then
    run sudo sed -i '/^ParallelDownloads = 20/a ILoveCandy' "$PACMAN_CONF"
  fi

  # pwfeedback en sudoers
  sudo grep -qE '^\s*Defaults\s+.*pwfeedback' /etc/sudoers || {
    sudo grep -q '^Defaults' /etc/sudoers && run sudo sed -i '/^Defaults/ a Defaults pwfeedback' /etc/sudoers ||
      run sudo sed -i '1i Defaults pwfeedback' /etc/sudoers
  }

  sudo visudo -c >/dev/null 2>&1 || run sudo sed -i '/^\s*Defaults\s+pwfeedback/d' /etc/sudoers
}

#############################
# FIREWALL
#############################
setup_firewall() {
  log "Instalando y configurando UFW..."
  run sudo pacman -S --noconfirm ufw
  run sudo systemctl enable ufw.service

  run sudo ufw default deny incoming
  run sudo ufw default allow outgoing
  # run sudo ufw allow ssh  # Descomentar si necesitas SSH

  run sudo ufw enable
  run sudo ufw status verbose
}

#############################
# AUR HELPER
#############################
install_yay() {
  log "Instalando yay..."
  run sudo pacman -Syu --needed git base-devel go --noconfirm

  if command -v yay &>/dev/null; then
    log "yay ya está instalado."
  else
    run git clone --depth 1 https://aur.archlinux.org/yay.git
    cd yay
    run makepkg -si --noconfirm --needed
    cd ..
    run rm -rf yay
  fi
}

#############################
# PAQUETES BASE
#############################
install_base_packages() {
  log "Instalando paquetes base..."
  run sudo pacman -S --needed --noconfirm \
    fzf git wget eza zsh neovim wl-clipboard openssh fastfetch \
    zoxide ttf-cascadia-code-nerd ttf-ubuntu-nerd yt-dlp ttf-input-nerd \
    firefox mpv starship inotify-tools inkscape libreoffice-fresh \
    obsidian gum hblock mise usage bat firefox
}

install_hyprland_packages() {
  log "Instalando Hyprland y dependencias..."
  run sudo pacman -S --needed --noconfirm \
    uwsm hyprland kitty rofi git xdg-user-dirs \
    xdg-desktop-portal-hyprland hyprpolkitagent \
    blueman pavucontrol hyprpaper waybar

  run yay -S --noconfirm --needed brave-bin
}

#############################
# SERVICIOS
#############################
setup_services() {
  log "Configurando servicios..."
  run systemctl --user enable --now hyprpolkitagent.service
  run sudo pacman -S --needed --noconfirm ly
  run sudo systemctl enable ly@tty2.service
  run sudo systemctl disable getty@tty2.service
}

#############################
# NVIM
#############################
setup_nvim() {
  log "Configurando Neovim..."
  run sudo pacman -S --needed --noconfirm nvim git wl-clipboard
  run git clone https://github.com/LazyVim/starter ~/.config/nvim
}

#############################
# FILE EXPLORER
#############################
setup_file_explorer() {
  log "Configurando explorador de archivos..."
  run sudo pacman -S --needed --noconfirm udisks2
  run sudo pacman -S --needed --noconfirm yazi ffmpeg 7zip jq poppler fd \
    ripgrep fzf zoxide resvg imagemagick

  run ya pkg add yazi-rs/plugins:mount

  mkdir -p ~/.config/yazi
  cat >~/.config/yazi/keymap.toml <<'EOF'
[[mgr.prepend_keymap]]
on  = "M"
run = "plugin mount"
EOF
}

#############################
# OH-MY-ZSH
#############################
setup_ohmyzsh() {
  log "Instalando Oh-My-Zsh y plugins..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    run sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  run git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  run git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  run git clone https://github.com/zsh-users/zsh-completions \
    ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
  run git clone https://github.com/zsh-users/zsh-history-substring-search \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
  run git clone https://github.com/Aloxaf/fzf-tab \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab

  run git clone --bare https://github.com/dotfn/.dotfn.git $HOME/.dotfn
  run git --git-dir=$HOME/.dotfn/ --work-tree=$HOME stash push
}

#############################
# LUCIDGLYPH
#############################
install_lucidglyph() {
  log "Instalando Lucidglyph..."
  run git clone "https://github.com/maximilionus/lucidglyph.git" "lucidglyph"
  run chmod +x "lucidglyph/lucidglyph.sh"
  run sudo "lucidglyph/lucidglyph.sh" install
  run rm -rf "lucidglyph"
}

#############################
# GRUB
#############################
configure_grub() {
  log "Configurando GRUB..."
  run sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub ||
    echo 'GRUB_TIMEOUT=0' | sudo tee -a /etc/default/grub >/dev/null

  command -v update-grub >/dev/null 2>&1 && run sudo update-grub >/dev/null 2>&1
  command -v grub-mkconfig >/dev/null 2>&1 && run sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
}

#############################
# CONFIGURACIONES FINALES
#############################
final_config() {
  log "Ejecutando configuraciones finales..."
  run hblock -n 10 -p 1
  run chsh -s $(which zsh)
  run fc-cache -f -v
}

#############################
# SCRIPT PRINCIPAL
#############################
main() {
  configure_pacman
  setup_firewall
  install_yay
  install_base_packages
  install_hyprland_packages
  setup_services
  setup_nvim
  setup_file_explorer
  setup_ohmyzsh
  install_lucidglyph
  configure_grub
  final_config
}

main
