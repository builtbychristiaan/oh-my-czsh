# Add Homebrew to PATH dynamically based on installation directory
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    # Default location for Homebrew on Linux / WSL
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d "$HOME/.linuxbrew" ]; then
    # Alternative home-directory installation
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
elif [ -d "/opt/homebrew" ]; then
    # macOS fallback (if you ever share this config with a Mac)
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export ZSH="$HOME/.oh-my-zsh"
export NVM_DIR=~/.nvm

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.console-ninja/.bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

