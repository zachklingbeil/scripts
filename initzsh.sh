#!/bin/bash

# Install zsh
if ! command -v zsh &> /dev/null; then
    sudo apt update
    sudo apt install zsh -y
fi
zsh --version

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
fi

# Clone zsh-autosuggestions plugin
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

# Clone zsh-syntax-highlighting plugin
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

# Add plugins to .zshrc
if ! grep -q "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" ~/.zshrc; then
    echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" >> ~/.zshrc
fi

# Source Oh My Zsh in .zshrc
if ! grep -q "source \$ZSH/oh-my-zsh.sh" ~/.zshrc; then
    echo "source \$ZSH/oh-my-zsh.sh" >> ~/.zshrc
fi