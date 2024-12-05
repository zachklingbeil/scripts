#!/bin/zsh

# Variables
USERNAME="zachklingbeil"
EMAIL="zach.zk@icloud.com"

# Git configuration
git config --global user.name "$USERNAME"
git config --global user.email "$EMAIL"
git config --global init.defaultBranch main

git config --global --unset gpg.format
git config --global gpg.format ssh
git config --global commit.gpgsign true

# Check if the SSH key exists
if [ -f "$HOME/.ssh/$USERNAME.pub" ]; then
    git config --global user.signingkey "$HOME/.ssh/$USERNAME.pub"
else
    echo "SSH key $HOME/.ssh/$USERNAME.pub not found. Please generate it before running this script."
    exit 1
fi

# Install GitHub CLI
if ! type -p wget >/dev/null; then
    sudo apt update
    sudo apt-get install wget -y
fi

sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y


# Check if Lua is installed
if ! command -v lua &> /dev/null; then
  echo "Lua is not installed. Installing Lua..."

  # Download and install Lua
  curl -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
  tar zxf lua-5.4.7.tar.gz
  cd lua-5.4.7
  make linux test
  sudo make install
  cd ..
  rm -rf lua-5.4.7 lua-5.4.7.tar.gz

  echo "Lua 5.4.7 installed successfully."
else
  echo "Lua is already installed."
  lua -v
fi

# Install Lua
sudo apt update
sudo apt install -y liblua5.4-dev luarocks

# Install Neovim and clone Neovim configuration files
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz
cd $HOME/.config
gh repo clone $USERNAME/nvim


# Add Tailscale's package signing key and repository, install, then start with SSH enabled
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install -y tailscale
sudo tailscale up --ssh


# Docker with NVIDIA container support
# Remove conflicts, Add Docker's official GPG key and repository
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg
done

sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Post-install steps
sudo usermod -aG docker $USER
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Add NVIDIA container apt repo
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Enable experimental features
sudo sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install NVIDIA container toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Setup Docker for NVIDIA
sudo nvidia-ctk runtime configure --runtime=docker --config=$HOME/.config/docker/daemon.json
sudo systemctl restart docker
sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place

# Update NVIDIA container runtime config
sudo sed -i 's/no-cgroups = true/no-cgroups = false/' /etc/nvidia-container-runtime/config.toml

# Install NVM and the latest LTS version of Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && nvm install --lts
npm install -g npm-check-updates

sudo apt-get install btop
sudo apt install fontconfig
sudo apt install fc-cache
sudo apt install lsd
timedatectl set-timezone America/Anchorage