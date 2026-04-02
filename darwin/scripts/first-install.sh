#!/bin/bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install --cask brave-browser
brew install bat
brew install fzf
brew install --cask ghostty
brew install --cask font-jetbrains-mono-nerd-font
brew install eza
brew install starship
brew install zoxide
brew install --cask visual-studio-code
brew install fastfetch
brew install gum
brew install hblock
hblock -n 10 -p 1

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

