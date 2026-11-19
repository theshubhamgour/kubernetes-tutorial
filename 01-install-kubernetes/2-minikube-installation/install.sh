#!/bin/bash
# install minikube environment

# install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo install kubectl /usr/local/bin/

# verify kubectl
kubectl version --client

# install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# verify minikube
minikube version

# start minikube cluster
minikube start --driver=docker --nodes=3

# verify cluster
kubectl get nodes
kubectl cluster-info
