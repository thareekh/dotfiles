#!/usr/bin/env bash
set -e

echo "==> 1. Installing C/C++, Embedded Toolchains, Neovim & CLI tools..."

if command -v pacman &> /dev/null; then
    echo "Detected: Arch-based distro"
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm \
        base-devel gcc gdb valgrind cmake make ninja clang lldb \
        arm-none-eabi-gcc arm-none-eabi-newlib arm-none-eabi-gdb openocd avr-gcc avr-libc avrdude picocom minicom \
        git curl wget neovim alacritty \
        ripgrep fd zoxide eza fzf fastfetch btop \
        nodejs npm python-pynvim unzip tar flatpak

elif command -v dnf &> /dev/null; then
    echo "Detected: Fedora-based distro"
    sudo dnf update -y
    sudo dnf install -y --skip-unavailable \
        gcc gcc-c++ gdb valgrind cmake make ninja-build clang clang-tools-extra lldb \
        arm-none-eabi-gcc-cs arm-none-eabi-newlib openocd avr-gcc avr-libc avrdude picocom minicom \
        git curl wget neovim alacritty \
        ripgrep fd-find zoxide eza fzf fastfetch btop \
        nodejs npm python3-neovim unzip tar flatpak

elif command -v apt &> /dev/null; then
    echo "Detected: Debian/Ubuntu-based distro"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y \
        build-essential gcc g++ gdb valgrind cmake make ninja-build clang clangd lldb \
        gcc-arm-none-eabi libnewlib-arm-none-eabi gdb-multiarch openocd gcc-avr avr-libc avrdude picocom minicom \
        git curl wget neovim alacritty \
        ripgrep fd-find zoxide eza fzf fastfetch btop \
        nodejs npm python3-neovim unzip tar flatpak
fi

echo "==> 2. Setting up Hardware / Dialout permissions..."
sudo usermod -aG dialout "$USER" 2>/dev/null || sudo usermod -aG uucp "$USER" 2>/dev/null || true

echo "==> 3. Installing JetBrainsMono Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    wget -qO /tmp/JetBrainsMono.tar.xz "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
    rm -f /tmp/JetBrainsMono.tar.xz
    fc-cache -fv || true
fi

echo "==> 4. Installing Tokyo Night GTK Theme & Icon Pack..."
mkdir -p "$HOME/.themes" "$HOME/.icons"

if [ ! -d "$HOME/.themes/TokyoNight-Dark-B" ]; then
    git clone --depth=1 https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme.git /tmp/tokyo-night-gtk
    cp -r /tmp/tokyo-night-gtk/themes/TokyoNight-Dark-B "$HOME/.themes/" 2>/dev/null || \
    cp -r /tmp/tokyo-night-gtk/src/TokyoNight-Dark-B "$HOME/.themes/" 2>/dev/null || true
    rm -rf /tmp/tokyo-night-gtk
fi

if [ ! -d "$HOME/.icons/Tela-dark" ]; then
    git clone --depth=1 https://github.com/vinceliuice/Tela-icon-theme.git /tmp/tela-icons
    /tmp/tela-icons/install.sh -d "$HOME/.icons" dark
    rm -rf /tmp/tela-icons
fi

echo "==> 5. Setting up LazyVim (C/C++ & Embedded LSP)..."
mkdir -p "$HOME/.config"
if [ -d "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%s)"
fi

git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"

mkdir -p "$HOME/.config/nvim/lua/plugins"
cat << 'EOF' > "$HOME/.config/nvim/lua/config/lazy.lua"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.clangd" },
    { import = "lazyvim.plugins.extras.lang.cmake" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  checker = { enabled = true },
})
EOF

nvim --headless "+Lazy! sync" +qa || true

echo "==> 6. Setting up Starship prompt & Shell Aliases..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

BASHRC="$HOME/.bashrc"
if ! grep -q "starship init bash" "$BASHRC"; then
    cat << 'EOF' >> "$BASHRC"

# CLI & Dev tools
eval "$(starship init bash)"
eval "$(zoxide init bash)"

alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias tree='eza --tree --icons'
alias v='nvim'
alias ff='fastfetch'
alias gdb='gdb -q'
alias serial='picocom -b 115200'
EOF
fi

echo "==> 7. Setting up Alacritty (Tokyo Night Theme)..."
mkdir -p "$HOME/.config/alacritty"
cat << 'EOF' > "$HOME/.config/alacritty/alacritty.toml"
[window]
padding = { x = 12, y = 12 }
opacity = 0.95

[font]
size = 11.5
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }

[colors.primary]
background = "#1a1b26"
foreground = "#c0caf5"

[colors.normal]
black = "#15161e"
red = "#f7768e"
green = "#9ece6a"
yellow = "#e0af68"
blue = "#7aa2f7"
magenta = "#bb9af7"
cyan = "#7dcfff"
white = "#a9b1d6"

[colors.bright]
black = "#414868"
red = "#f7768e"
green = "#9ece6a"
yellow = "#e0af68"
blue = "#7aa2f7"
magenta = "#bb9af7"
cyan = "#7dcfff"
white = "#c0caf5"
EOF

echo "==> 8. Applying Themes, Wallpaper & GNOME Settings..."
mkdir -p "$HOME/Pictures/Wallpapers"
WALLPAPER_FILE="$HOME/Pictures/Wallpapers/wallpaper.jpg"

curl -fsSLo "$WALLPAPER_FILE" "https://raw.githubusercontent.com/thareekh/dotfiles/main/wallpaper.jpg"

if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gsettings set org.gnome.desktop.interface clock-show-weekday true
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

    gsettings set org.gnome.desktop.interface gtk-theme "TokyoNight-Dark-B" || true
    gsettings set org.gnome.desktop.interface icon-theme "Tela-dark" || true

    if [ -f "$WALLPAPER_FILE" ]; then
        gsettings set org.gnome.desktop.background picture-uri "file://${WALLPAPER_FILE}"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_FILE}"
        gsettings set org.gnome.desktop.background picture-options 'zoom'
    fi
fi

echo "==> 9. Installing Desktop GUI Applications via Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

APPS=(
    com.brave.Browser
    org.videolan.VLC
    net.lutris.Lutris
    com.heroicgameslauncher.hgl
    com.github.mtkennerly.ludusavi
    org.telegram.desktop
    com.rtosta.zapzap
)

flatpak install -y flathub "${APPS[@]}"

echo "=========================================================="
echo " Setup complete! Tokyo Night Theme, Wallpaper & Dev Tools "
echo " successfully installed and applied!                      "
echo "=========================================================="
