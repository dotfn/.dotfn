#!/bin/bash

##

configure_pacman() {
  PACMAN_CONF="/etc/pacman.conf"

  # Habilitar Color si no está habilitado
  if ! grep -qE '^[[:space:]]*Color' "$PACMAN_CONF"; then
    sudo sed -i 's/#Color/Color/' "$PACMAN_CONF"
  fi

  # Ajustar ParallelDownloads a 20 si no está
  if ! grep -qE '^ParallelDownloads\s*=\s*20' "$PACMAN_CONF"; then
    sudo sed -i 's/^ParallelDownloads\s*=\s*[0-9]\+/ParallelDownloads = 20/' "$PACMAN_CONF"
  fi

  # Agregar ILoveCandy si no está
  if ! grep -q 'ILoveCandy' "$PACMAN_CONF"; then
    sudo sed -i '/^ParallelDownloads = 20/a ILoveCandy' "$PACMAN_CONF"
  fi

  sudo grep -qE '^\s*Defaults\s+.*pwfeedback' /etc/sudoers || {
    sudo grep -q '^Defaults' /etc/sudoers && sudo sed -i '/^Defaults/ a Defaults pwfeedback' /etc/sudoers ||
      sudo sed -i '1i Defaults pwfeedback' /etc/sudoers
  }

  sudo visudo -c >/dev/null 2>&1 || sudo sed -i '/^\s*Defaults\s+pwfeedback/d' /etc/sudoers

}

configure_pacman

###---------------------------
### FIREWALL - ufw
###---------------------------
sudo pacman -S --noconfirm ufw gufw
sudo systemctl enable ufw.service

sudo ufw default deny incoming
sudo ufw default allow outgoing

# Agrega otras reglas según tus servicios necesarios
#sudo ufw allow ssh

sudo ufw enable
sudo ufw status verbose

###---------------------------
### AUR helper
###---------------------------
sudo pacman -Syu --needed git base-devel go --noconfirm
if command -v yay &>/dev/null; then
  echo "yay ya está instalado."
else
  git clone --depth 1 https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm --needed
  cd ..
  rm -rf yay
fi

###---------------------------
### BASE
###---------------------------

sudo pacman -S --needed --noconfirm fzf \
  git \
  wget \
  eza \
  zsh \
  neovim \
  wl-clipboard \
  openssh \
  fastfetch \
  zoxide \
  ttf-cascadia-code-nerd \
  ttf-ubuntu-nerd \
  yt-dlp \
  ttf-input-nerd \
  firefox \
  mpv \
  starship \
  inotify-tools \
  inkscape \
  libreoffice-fresh \
  obsidian \
  gum \
  hblock \
  mise \
  usage \
  bat

#### BASE INSTALL hyprland PACK
sudo pacman -S --needed --noconfirm uwsm hyprland kitty rofi firefox git xdg-user-dirs xdg-desktop-portal-hyprland hyprpolkitagent

####
yay -S --noconfirm --needed brave-bin

##### SERVICES
#sudo systemctl enable hyprpolkitagent.service
systemctl --user enable --now hyprpolkitagent.service

##### SESSION MANAGER
sudo pacman -S --needed --noconfirm ly

sudo systemctl enable ly@tty2.service
sudo systemctl disable getty@tty2.service

#### NVIM EDITOR
sudo pacman -S --needed --noconfirm nvim git wl-clipboard
git clone https://github.com/LazyVim/starter ~/.config/nvim

#### FILE EXPLORER
sudo pacman -S --needed --noconfirm udisks2
sudo pacman -S --needed --noconfirm yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick

ya pkg add yazi-rs/plugins:mount

mkdir -p ~/.config/yazi && cat >~/.config/yazi/keymap.toml <<'EOF'
[[mgr.prepend_keymap]]
on  = "M"
run = "plugin mount"
EOF

###---------------------------
### CONFIG
###---------------------------
hblock -n 10 -p 1
chsh -s $(which zsh)

###----------------------------
### OH-MY-ZSH
###----------------------------

RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
  sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions \
  ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/Aloxaf/fzf-tab \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab

alias dot='git --git-dir=$HOME/.dotfn/ --work-tree=$HOME'
git clone --bare https://github.com/dotfn/.dotfn.git $HOME/.dotfn
dot stash push

fc-cache -f -v

###---------------------------
### INSTALACIÓN DE LUCIDGLYPH
###---------------------------
git clone "https://github.com/maximilionus/lucidglyph.git" "lucidglyph"
chmod +x "lucidglyph/lucidglyph.sh"
sudo "lucidglyph/lucidglyph.sh" install
rm -rf "lucidglyph"

##### GRUB
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub || echo 'GRUB_TIMEOUT=0' | sudo tee -a /etc/default/grub >/dev/null
command -v update-grub >/dev/null 2>&1 && sudo update-grub >/dev/null 2>&1
command -v grub-mkconfig >/dev/null 2>&1 && sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
