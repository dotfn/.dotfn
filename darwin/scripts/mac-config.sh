#!/bin/bash
defaults write com.apple.finder AppleShowAllFiles true && killall Finder
defaults write com.apple.finder ShowPathbar -bool true && killall Finder
defaults write com.apple.dock autohide-delay -float 0 && defaults write com.apple.dock autohide-time-modifier -float 0.4 && killall Dock
touch ~/.hushlogin