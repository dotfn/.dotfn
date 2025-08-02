#!/bin/bash
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME' 

sudo pacman -Syy

grep -q '^Color' /etc/pacman.conf || sudo sed -i '/^\[options\]/a Color' /etc/pacman.conf
grep -q '^ILoveCandy' /etc/pacman.conf || sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

###System 
sudo pacman -S \
	git \
	wget \
	eza \
	zsh \
	neovim \
	openssh \

###hyprland base
sudo pacman -S  \
	hyprland \
	ly \
	uwsm \
	kitty \
	rofi \
	xdg-desktop-portal-gtk \
	xdg-desktop-portal-hyprland \
	xdg-user-dirs \
	hyprpolkitagent \
	hyprpaper

### hyprland ecosystem
sudo pacman -S hyprsunset

# ly config 
sudo systemctl enable ly.service
sudo systemctl disable getty@tty2.service

# enable autostart hypr polkit
systemctl --user enable --now hyprpolkitagent.service

# enable services
systemctl --user enable --now hyprsunset.service
systemctl --user enable --now hyprpaper.service

###----------------------------
### Yazi file explorer
###----------------------------
sudo pacman -S yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick udisks2

# Yazi plugins
ya pkg add yazi-rs/plugins:mount

###----------------------------
### oh-my-zsh
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

#cross-shell prompt
sudo pacman -S starship

#Apps
sudo pacman -S \
	ttf-input-nerd \
	firefox	\
	mpv \
	bluetui \
	wiremix \

# Install AUR helper
sudo pacman -Syu --needed git base-devel --noconfirm
# Verifica si yay ya está instalado
if command -v yay &>/dev/null; then
    echo "yay ya está instalado."
else
    git clone --depth 1 https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm --needed
    cd ..
    rm -rf yay
    echo "yay se ha instalado correctamente de forma desatendida."
fi

##Set dotfiles
git clone --bare https://github.com/dotfn/.dotfn.git $HOME/.dotfiles
dot stash push

##
chsh -s $(which zsh)

