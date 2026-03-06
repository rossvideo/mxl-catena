#!/bin/bash

set -e

echo "==> Getting hostname..."
HOSTNAME=$(hostname)
echo "Hostname: $HOSTNAME"

# --------------------------------------------------
# Update apt
# --------------------------------------------------
echo "==> Updating system..."
apt update
apt upgrade -y

# --------------------------------------------------
# Create ansible user and configure SSH
# --------------------------------------------------
echo "==> Creating ansible user..."

if ! id "ansible" &>/dev/null; then
    useradd -m -s /bin/bash ansible
    usermod -aG sudo ansible
fi

mkdir -p /home/ansible/.ssh

if [ -f "./id_ed25519.pub" ]; then
    cat ./id_ed25519.pub > /home/ansible/.ssh/authorized_keys
else
    echo "ERROR: id_ed25519.pub not found in current directory"
    exit 1
fi

chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/.ssh

echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
chmod 440 /etc/sudoers.d/ansible

# --------------------------------------------------
# Install git and other dependencies
# --------------------------------------------------

echo "==> Installing git and other dependencies..."
apt install -y git apt-transport-https ca-certificates curl software-properties-common python3-pip virtualenv python3-setuptools

# --------------------------------------------------
# Install docker
# --------------------------------------------------


echo "==> Checking if Docker is already installed..."

if command -v docker &> /dev/null; then
    echo "Docker is already installed:"
    docker --version
    DOCKER_INSTALLED=true
else
    echo "Docker is not installed."
    DOCKER_INSTALLED=false
fi


# --------------------------------------------------
# Install Docker if missing
# --------------------------------------------------
if [ "$DOCKER_INSTALLED" = false ]; then

    echo "==> Installing prerequisites..."
    apt update

    apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    install -m 0755 -d /etc/apt/keyrings

    echo "==> Adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "==> Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list

    apt update

    echo "==> Installing Docker..."
    apt install -y docker-ce docker-ce-cli containerd.io

fi


# --------------------------------------------------
# Ensure docker group exists
# --------------------------------------------------
echo "==> Ensuring docker group exists..."
groupadd -f docker


# --------------------------------------------------
# Allow ansible user to use Docker
# --------------------------------------------------
if id "ansible" &>/dev/null; then
    echo "==> Adding ansible user to docker group..."
    usermod -aG docker ansible
else
    echo "WARNING: ansible user does not exist."
fi


# --------------------------------------------------
# Configure Docker daemon.json (HARD REQUIREMENTS KEPT)
# --------------------------------------------------
echo "==> Configuring /etc/docker/daemon.json..."

mkdir -p /etc/docker

cat > /etc/docker/daemon.json <<EOF
{
  "bip": "192.168.0.250/24",
  "default-address-pools": [
    { "base": "192.168.1.0/24", "size": 24 }
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "icc": false,
  "userland-proxy": false,
  "live-restore": true
}
EOF

chmod 644 /etc/docker/daemon.json


# --------------------------------------------------
# Remove insecure TCP exposure if present
# --------------------------------------------------
if [ -f /etc/systemd/system/docker.service.d/override.conf ]; then
    echo "==> Removing insecure TCP override..."
    rm -f /etc/systemd/system/docker.service.d/override.conf
fi


# --------------------------------------------------
# Reload and restart Docker
# --------------------------------------------------
echo "==> Reloading systemd..."
systemctl daemon-reload

echo "==> Enabling Docker..."
systemctl enable docker

echo "==> Restarting Docker..."
systemctl restart docker


# --------------------------------------------------
# Secure Docker socket permissions
# --------------------------------------------------
if [ -S /var/run/docker.sock ]; then
    echo "==> Securing Docker socket..."
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi


# --------------------------------------------------
# Test Docker
# --------------------------------------------------
echo "==> Testing Docker..."
docker --version

echo ""
echo "==> Docker hardened setup complete."
echo "IMPORTANT: ansible user must log out and back in for docker group to apply."


# --------------------------------------------------
# Reboot
# --------------------------------------------------
echo "==> Rebooting system..."
reboot