#!/bin/bash
set -e

echo "===== Kubernetes WORKER Setup (Auto) ====="

# Generate unique hostname based on IP
IP=$(hostname -I | awk '{print $1}')
HOSTNAME="worker-$(echo $IP | tr '.' '-')"

echo "Setting hostname to $HOSTNAME"
sudo hostnamectl set-hostname $HOSTNAME

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Install containerd
sudo apt update
sudo apt install -y containerd apt-transport-https ca-certificates curl

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# Add Kubernetes repo
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.asc

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes tools
sudo apt update
sudo apt install -y kubelet kubeadm
sudo apt-mark hold kubelet kubeadm

echo ""
echo "===== WORKER SETUP COMPLETE ====="
echo "Hostname: $HOSTNAME"
echo ""
echo "👉 NEXT STEP:"
echo "Run the join command from MASTER like below:"
echo ""
echo "sudo kubeadm join <MASTER-IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH> --v=5"
echo ""
echo "After joining, verify on MASTER:"
echo "kubectl get nodes"
