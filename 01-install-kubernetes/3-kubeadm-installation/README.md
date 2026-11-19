# Kubernetes Cluster Setup on AWS EC2 (1 Master + N Workers)

This guide helps you create a **Kubernetes cluster using kubeadm** on AWS EC2.

It is optimized for:
- Learning
- Demos
- DevOps projects

---

# 🧱 Architecture

- 1 Master Node (Control Plane)
- Multiple Worker Nodes

---

# ☁️ AWS EC2 Configuration

## ✅ Master Node

- Instance Type: `t3.small`
- RAM: 2GB
- CPU: 2 vCPU
- Storage: **30 GB (gp3)**
- OS: Ubuntu 22.04

---

## ✅ Worker Nodes

- Instance Type: `t3.micro`
- RAM: 1GB
- CPU: 2 vCPU
- Storage: **20 GB (gp3)**
- OS: Ubuntu 22.04

---

## 🔐 Security Group (IMPORTANT)

### Inbound Rules (All Security Group Rules)

#### Master Node (Control Plane)
| Protocol | Port(s) | Source | Purpose |
|----------|---------|--------|---------|
| TCP | 22 | 0.0.0.0/0 | SSH access |
| TCP | 6443 | Worker nodes | Kubernetes API server |
| TCP | 2379-2380 | Master nodes | etcd (control plane) |
| TCP | 10250 | Master & Worker nodes | Kubelet API |
| TCP | 10251 | Master nodes | kube-scheduler |
| TCP | 10252 | Master nodes | kube-controller-manager |

#### Worker Nodes
| Protocol | Port(s) | Source | Purpose |
|----------|---------|--------|---------|
| TCP | 22 | 0.0.0.0/0 | SSH access |
| TCP | 10250 | Master node | Kubelet API |
| TCP | 30000-32767 | 0.0.0.0/0 | NodePort Services |

#### Optional (For Internal Communication)
| Protocol | Port(s) | Source | Purpose |
|----------|---------|--------|---------|
| ICMP | All | 0.0.0.0/0 | Ping/diagnostics |
| TCP | 10255 | Master & Worker nodes | Kubelet read-only API |

👉 **Key Port for Worker-to-Master Communication:** `6443`

👉 **For Lab Environments:** Allow all traffic between security group members (intra-SG communication)

👉 **Example AWS Security Group Inbound Rules:**
```
- Type: All TCP, Source: Security Group ID (self-reference)
- Type: SSH, Port 22, Source: 0.0.0.0/0
- Type: Custom TCP, Port 6443, Source: Security Group ID (for kubeadm join)
- Type: Custom TCP, Port 30000-32767, Source: 0.0.0.0/0 (for NodePort access)
```

---

# ⚙️ MASTER SETUP

## Step 1: Clone the git repo

git clone https://github.com/theshubhamgour/kubernetes-tutorial
cd kubernetes-tutorial
cd 1-install-kubernetes

---

## Prerequisite: Install Docker and runtime dependencies

Before running the master or worker setup scripts, run `docker-install.sh` on every node to install Docker and configure the container runtime.

```bash
chmod +x docker-install.sh
./docker-install.sh
```

---

## Step 2: Run script

chmod +x k8s-master-clean.sh
./master-node-setup.sh

---

## 🧠 What this script does

- Sets hostname to `master`
- Disables swap
- Configures kernel networking
- Installs containerd
- Enables SystemdCgroup
- Installs kubeadm, kubelet, kubectl
- Initializes cluster
- Configures kubectl
- Installs Calico network

---

## 📌 Output

kubeadm join <MASTER-IP>:6443 --token ... --discovery-token-ca-cert-hash sha256:...

---

# 🧱 WORKER SETUP

## Step 1: Copy script to worker

git clone https://github.com/theshubhamgour/kubernetes-tutorial
cd kubernetes-tutorial
cd 1-install-kubernetes

---

## Step 2: Run script

chmod +x *.sh
./worker-node-setup.sh

---

## Step 3: Join cluster

sudo kubeadm join <MASTER-IP>:6443 \
--token <TOKEN> \
--discovery-token-ca-cert-hash sha256:<HASH> \
--v=5

---

# 🔍 VERIFY CLUSTER

kubectl get nodes

---

## ✅ Expected Output

master            Ready
worker-172-31-x   Ready
worker-172-31-x   Ready

---

# 📦 VERIFY PODS

kubectl get pods -A

All should be Running

---

# 🧠 COMMAND EXPLANATION

## kubeadm init
Initializes Kubernetes control plane

## kubeadm join
Joins worker to cluster

## kubectl get nodes
Shows cluster nodes

## kubectl get pods -A
Shows all pods

---

# ⚠️ IMPORTANT NOTES

- Always disable swap
- All nodes must be in same VPC
- Internet must be enabled
- Wait 1–2 minutes after setup

---

# 🎯 FINAL RESULT

- 1 Master node
- N Worker nodes
- Fully working Kubernetes cluster

---
---
---

---

## 📝 Additional notes

- **Lost or expired join command:** join tokens expire after 24 hours by default. Generate a fresh command on the control plane with `kubeadm token create --print-join-command`.
- **Nodes stuck in `NotReady`:** this usually means no CNI network plugin is running yet. Check with `kubectl get pods -n kube-system` and `kubectl describe node <node>`.
- **Upgrades:** don't skip minor versions when you upgrade. Follow the official kubeadm upgrade steps one minor version at a time.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Installing kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
