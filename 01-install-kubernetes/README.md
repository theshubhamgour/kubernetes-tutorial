# Kubernetes Installation Options

This folder contains three different Kubernetes installation approaches. Each subfolder has its own README and install scripts.

## 1. kind installation (`1-kind-installation`)
- Purpose: Local Kubernetes cluster using KIND.
- Good when: you want a lightweight local cluster for development or learning on Ubuntu.
- What is present:
  - `Readme.md`: installation documentation and command explanations.
  - `install.sh`: script with the exact same commands from the README.
- Why use it: KIND runs Kubernetes nodes as Docker containers, so it is simple and fast for testing without VMs.

## 2. minikube installation (`2-minikube-installation`)
- Purpose: Local Kubernetes cluster using Minikube with Docker driver.
- Good when: you want another common local Kubernetes option that starts a cluster with Minikube.
- What is present:
  - `Readme.md`: installation documentation for Docker, kubectl, and Minikube.
  - `install.sh`: script based on the README with the same commands.
- Why use it: Minikube is useful for local development and supports multi-node clusters with a simple Docker-based setup.

## 3. kubeadm installation (`3-kubeadm-installation`)
- Purpose: Kubernetes cluster setup using kubeadm, designed for cloud or VM-based clusters.
- Good when: you want a more realistic cluster setup on AWS EC2 or similar environments.
- What is present:
  - `README.md`: detailed guide for kubeadm cluster creation, AWS instance setup, and verification.
  - `docker-install.sh`: install Docker and container runtime dependencies, then configure the node for kubeadm.
  - `master-node-setup.sh`: prepare and initialize the control plane node.
  - `worker-node-setup.sh`: prepare worker nodes to join the cluster.
- Why use it: kubeadm gives a production-like multi-node cluster experience and is appropriate for learning cluster operations and real deployments.
- Important port: the Kubernetes API server port `6443` must be exposed between master and worker nodes.

## Which folder should you choose?
- Use `1-kind-installation` for quick local experiments and demos.
- Use `2-minikube-installation` if you prefer Minikube or want a local Docker-driven cluster alternative.
- Use `3-kubeadm-installation` when you need a real cluster setup on VMs or cloud instances and want to practice kubeadm workflows.
---
---

---

## 📝 Additional notes

- **Switching clusters:** if you try more than one option, each cluster gets its own context. Use `kubectl config get-contexts` to list them and `kubectl config use-context <name>` to switch.
- **Check versions:** `kubectl version` shows your client and server versions. Kubernetes supports `kubectl` within one minor version of the API server.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Install tools](https://kubernetes.io/docs/tasks/tools/)
- [Production environment and cluster setup options](https://kubernetes.io/docs/setup/production-environment/)
- [Organize cluster access with kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
