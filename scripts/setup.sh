#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl git

# Install Docker Engine using Docker's official repository.
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
usermod -aG docker vagrant

# Install Ollama.
curl -fsSL https://ollama.com/install.sh | sh

systemctl enable --now ollama

# Pull a small model suitable for a CPU-only lab.
# Change this later if you want to experiment with another model.
sudo -u vagrant ollama pull qwen2.5:3b

echo
 echo "============================================="
echo " LLM Lab ready"
echo "============================================="
echo "Ollama API: http://192.168.56.30:11434"
echo "Model:      qwen2.5:3b"
echo
echo "Test from inside the VM:"
echo "  curl http://localhost:11434/api/tags"
echo
echo "Test generation:"
echo "  curl http://localhost:11434/api/generate -d '{\"model\":\"qwen2.5:3b\",\"prompt\":\"Explain Kubernetes in one sentence.\",\"stream\":false}'"
echo "============================================="
