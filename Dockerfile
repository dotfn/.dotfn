FROM debian:trixie-slim

# ── Evitar prompts interactivos ───────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ── Paquetes base del sistema ─────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget unzip zip \
    build-essential ca-certificates gnupg \
    openssh-client sudo \
    zsh \
    fzf bat ripgrep btop neovim fastfetch\
    && rm -rf /var/lib/apt/lists/*

# ── eza (ls moderno) — repo oficial Debian ───────────────────────────────────
RUN wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
       > /etc/apt/sources.list.d/gierens.list \
    && chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list \
    && apt-get update && apt-get install -y eza \
    && rm -rf /var/lib/apt/lists/*

# ── starship ──────────────────────────────────────────────────────────────────
RUN curl -sSfL https://starship.rs/install.sh | sh -s -- --yes --bin-dir /usr/local/bin

# ── zoxide (cd inteligente) ───────────────────────────────────────────────────
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir /usr/local/bin

# ── Usuario no-root ───────────────────────────────────────────────────────────
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /usr/bin/zsh $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

# ── fnm (Node version manager) ───────────────────────────────────────────────
ENV FNM_PATH="/home/$USERNAME/.local/share/fnm"
ENV PATH="$FNM_PATH:$PATH"

RUN curl -fsSL https://fnm.vercel.app/install | bash
RUN fnm install --lts && fnm default lts-latest

ENV PNPM_HOME="/home/dev/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN fnm exec --using=lts-latest -- npm install -g pnpm \
    && fnm exec --using=lts-latest -- pnpm config set global-bin-dir /home/dev/.local/share/pnpm
    
# ── opencode ─────────────────────────────────────────────────────────────────
RUN fnm exec --using=lts-latest -- pnpm install -g opencode-ai

# ── oh-my-zsh ────────────────────────────────────────────────────────────────
RUN RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# ── Plugins de oh-my-zsh ─────────────────────────────────────────────────────
RUN git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" \
    && git clone --depth=1 https://github.com/zsh-users/zsh-completions \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" \
    && git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search" \
    && git clone --depth=1 https://github.com/Aloxaf/fzf-tab \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"

# ── .zshrc ────────────────────────────────────────────────────────────────────
COPY --chown=$USERNAME:$USERNAME .zshrc /home/$USERNAME/.zshrc

# ── Git: config base ──────────────────────────────────────────────────────────
RUN git config --global init.defaultBranch main \
    && git config --global pull.rebase false \
    && git config --global core.editor "nvim"

# ── Workspace ─────────────────────────────────────────────────────────────────
WORKDIR /workspace

CMD ["zsh"]