#!/bin/bash
set -e

echo "===== Kubernetes (kubeadm, kubelet, kubectl) Installation ====="

# Update system
sudo apt-get update

# Install required packages
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Create keyrings directory if not exists
sudo mkdir -p -m 755 /etc/apt/keyrings

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list again
sudo apt-get update

# Install kubeadm, kubelet, kubectl
sudo apt-get install -y kubelet kubeadm kubectl

# Hold versions
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
sudo systemctl enable --now kubelet

echo ""
echo "===== Kubernetes Installation Complete ====="
echo "Verify:"
echo "kubeadm version"
echo "kubectl version --client"
echo "kubelet --version"
