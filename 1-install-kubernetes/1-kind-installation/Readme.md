# KIND Kubernetes Installation Guide

This README provides step-by-step instructions to install Docker, KIND, and kubectl on Ubuntu, then create and verify a local Kubernetes cluster with one control-plane node and two worker nodes.

## Requirements
- Ubuntu-based Linux distribution
- Internet access to download Docker, KIND, and kubectl
- sudo privileges

## Overview
This guide explains how to:
- update Ubuntu packages,
- install and start Docker,
- install KIND and kubectl,
- create a local KIND cluster,
- verify that the cluster is running, and
- delete the cluster when no longer needed.

## Install script
You can run `install.sh` to automate the Docker, KIND, and kubectl installation steps, then create the local cluster.

## Installation Steps

### 1. Update Ubuntu
Update the package lists and install available updates so the system has the latest security and stability fixes.

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Docker
Install Docker from Ubuntu repositories. KIND uses Docker to run Kubernetes nodes as containers.

```bash
sudo apt install docker.io -y
```

### 3. Enable the Docker service
Enable Docker to start automatically on boot so the service is available after system restarts.

```bash
sudo systemctl enable docker
```

### 4. Start Docker
Start the Docker service now so subsequent KIND and container operations can run.

```bash
sudo systemctl start docker
```

### 5. Verify Docker
Confirm Docker is installed correctly and that the daemon is running.

```bash
docker --version
docker ps
```

### 6. Install KIND
Download the KIND binary for x86_64 architecture, make it executable, and move it to a system path so it can be run from anywhere.

```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### 7. Verify KIND
Check that KIND was installed successfully and is accessible from the command line.

```bash
kind version
```

### 8. Install kubectl
Download the latest stable kubectl client, make it executable, and move it into a directory on your PATH.

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### 9. Verify kubectl
Ensure the kubectl client is installed and can report its version.

```bash
kubectl version --client
```

### 10. Create a Kubernetes cluster
Create a KIND configuration file with one control-plane node and two worker nodes. This is a common test cluster topology for local development.

```bash
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

Then create the cluster using the configuration file.

```bash
kind create cluster --name dev-cluster --config kind-config.yaml
```

### 11. Verify the cluster
Confirm that the KIND cluster exists and that the Kubernetes nodes are ready.

```bash
kind get clusters
kubectl get nodes
```

### 12. Delete the cluster (if needed)
Remove the KIND cluster when you are finished with it to free system resources.

```bash
kind delete cluster --name dev-cluster
```

---

## 🔐 Ports & Services Documentation

### KIND Cluster Ports
Since KIND runs locally in Docker containers, the following ports are important:

| Protocol | Port(s) | Purpose |
|----------|---------|----------|
| TCP | 6443 | Kubernetes API server (kubectl) |
| TCP | 10250 | Kubelet API |
| TCP | 30000-32767 | NodePort Services |
| TCP | 8080 | kubectl proxy (if used) |

### Network Access
- KIND clusters are **local only** and accessible from localhost
- Services are accessed via `localhost:<port>` or `127.0.0.1:<port>`
- NodePort services are available on port range 30000-32767
- No firewall/security group configuration needed for local development

### Accessing Services
```bash
# Get service details
kubectl get svc

# Access NodePort service
curl http://localhost:30000  # Example NodePort

# Port-forward for direct access
kubectl port-forward svc/<service-name> 8080:80
```

---
---

---

## 📝 Additional notes

- **Using local images:** a kind cluster can't see images in your local Docker cache. Load them with `kind load docker-image <image>:<tag>`.
- **Reaching apps from your machine:** kind nodes are containers, so a NodePort isn't automatically open on your host. For quick tests, use `kubectl port-forward`. For permanent access, set `extraPortMappings` in the kind config.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Install tools: kind](https://kubernetes.io/docs/tasks/tools/#kind)
- [Install and set up kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Use port forwarding to access applications](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
