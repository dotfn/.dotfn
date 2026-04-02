eval "$(/opt/homebrew/bin/brew shellenv)"

# ── XDG Base Directory Specification ─────────────────────────────────────────
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_BIN_HOME="$HOME/.local/bin"
export PATH="$XDG_BIN_HOME:$PATH"

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# ── Oh-My-Zsh ────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Desactivado: usamos starship

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
  fzf-tab
)

source $ZSH/oh-my-zsh.sh

# ── fnm (Node version manager) ───────────────────────────────────────────────
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
eval "$(fnm env --use-on-cd --shell zsh)"

# ── zoxide ────────────────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── starship ──────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Historial ─────────────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ── history-substring-search (flechas ↑↓) ────────────────────────────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ── Aliases ───────────────────────────────────────────────────────────────────
alias ls="eza --icons=auto"
alias ll="eza -lah --icons=auto --git"
alias la="eza -a --icons=auto"
alias lt="eza --tree --icons=auto -L 2"

alias cat="bat --style=auto"

# zoxide reemplaza cd (z aprende tus directorios)
alias cd="z"

# git
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gpl="git pull"
alias glog="git log --oneline --graph --all"
