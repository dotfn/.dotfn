#-----------------------------------------------------------
# PATH
#-----------------------------------------------------------
export XDG_BIN_HOME="$HOME/.local/bin"
export PATH="$XDG_BIN_HOME:$PATH"

#-----------------------------------------------------------
# XDG Base Directory Specification
#-----------------------------------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_BIN_HOME="$HOME/.local/bin"

#-----------------------------------------------------------
# Wayland support (apps deben poder detectarlo)
#-----------------------------------------------------------
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM="wayland"
export SDL_VIDEODRIVER="wayland"
export CLUTTER_BACKEND="wayland"
export XDG_SESSION_TYPE="wayland"
export GDK_BACKEND="wayland,x11"

#-----------------------------------------------------------
# PATH prioritizing user-level binaries
#-----------------------------------------------------------
export PATH="$XDG_BIN_HOME:$PATH"

#-----------------------------------------------------------
# Default applications
#-----------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="kitty"
export BROWSER="firefox"
export MANPAGER="nvim +Man!"

#-----------------------------------------------------------
# Language / Locale (opcional, pero útil en entorno minimal)
#-----------------------------------------------------------
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

#-----------------------------------------------------------
# GTK applications
#-----------------------------------------------------------
export GTK_APPLICATION_PREFER_DARK_THEME=1

