# Kubernetes YAML Made Easy ☸️

## Overview

This folder contains the notes, examples, and hands-on practice files used in the **Kubernetes YAML Made Easy** tutorial.

---

# Ways to Create Kubernetes Resources

Kubernetes resources can be created using:

### 1. Command Method

Suitable for small resources.

```bash
kubectl create namespace dev
```

### 2. YAML Method ✅ (Recommended)

Used in real-world projects.

```bash
kubectl apply -f resource.yaml
```

### 3. Edit Method

```bash
kubectl edit pod nginx
```

---

# What is YAML?

YAML is a configuration language used to define Kubernetes resources.

YAML is based on **key-value pairs**.

Linux:

```bash
name=shubham
```

YAML:

```yaml
name: shubham
```

---

# YAML Start and End Markers

Start Marker:

```yaml
---
```

End Marker:

```yaml
...
```

Example:

```yaml
---
name: shubham
age: 25
...
```

---

# Key Value Pairs

```yaml
name: shubham
age: 25
address: nagpur
```

---

# Lists in YAML

```yaml
colors:
  - red
  - blue
  - green
  - yellow
```

Another Example:

```yaml
users:
  - raju
  - ghanshyam
  - baburao
```

---

# Nested Objects

```yaml
user:
  name: raju
  age: 25
  address: nagpur
```

---

# Nested Objects Inside Nested Objects

```yaml
user:
  name: raju
  age: 25
  address:
    current: nagpur
    residence: hyderabad
  group: devops
```

---

# YAML Variables

```yaml
{{user}}
{{group}}
{{user.name}}
{{user.address.residence}}
```

Examples:

```yaml
{{group}} -> devops
{{user.name}} -> raju
{{user.address.residence}} -> hyderabad
```

---

# Indentation Rules

⚠️ Indentation is extremely important in YAML.

Parent key must be written before child keys.

Correct:

```yaml
user:
  name: raju
  age: 25
```

Incorrect:

```yaml
user:
name: raju
age: 25
```

---

# Kubernetes YAML Keywords

Most Kubernetes YAML files contain these four keywords:

```yaml
apiVersion
kind
metadata
spec
```

---

## 1. apiVersion

Defines the Kubernetes API version.

Examples:

```yaml
apiVersion: v1
```

```yaml
apiVersion: apps/v1
```

---

## 2. kind

Defines the Kubernetes resource type.

Examples:

```yaml
kind: Pod
```

```yaml
kind: Deployment
```

```yaml
kind: Namespace
```

---

## 3. metadata

Stores information about the resource.

Example:

```yaml
metadata:
  name: demo
```

Labels:

```yaml
metadata:
  name: demo
  labels:
    app: webapp
```

---

## 4. spec

Contains the actual configuration.

Example:

```yaml
spec:
  replicas: 3
```

---

# Understanding Namespaces

Namespace is a virtual Kubernetes resource used for isolation.

Namespaces help separate:

- Pods
- Deployments
- Secrets
- ConfigMaps
- Services

Common Namespaces:

```text
default
kube-system
kube-public
kube-node-lease
```

List Namespaces:

```bash
kubectl get ns
```

---

# kube-system Namespace

Contains Kubernetes internal components.

```bash
kubectl get pods -n kube-system
```

---

# Create Namespace Using Command

Create:

```bash
kubectl create namespace dev
```

or

```bash
kubectl create ns prod
```

View:

```bash
kubectl get ns
```

Delete:

```bash
kubectl delete namespace dev
```

---

# Create Namespace Using YAML

Create file:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: testing
  labels:
    app: test
```

Apply:

```bash
kubectl apply -f demo.yaml
```

Verify:

```bash
kubectl get ns
```

Show Labels:

```bash
kubectl get ns --show-labels
```

Describe Namespace:

```bash
kubectl describe namespace testing
```

---

# Find Available Kubernetes Resources

```bash
kubectl api-resources
```

---

# Create Pod Inside Namespace

Create file:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: newapp
  namespace: prod

spec:
  containers:
    - name: app
      image: nginx
      ports:
        - containerPort: 80
```

Apply:

```bash
kubectl apply -f newpod.yaml
```

Verify:

```bash
kubectl get pod -n prod
```

Detailed View:

```bash
kubectl get pod -o wide -n prod
```

---

# Delete Pod

```bash
kubectl delete pod newapp -n prod
```

---

# YAML Manifest Example: Pod

A simple Pod manifest looks like this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80
```

### What each field means

- `apiVersion`: tells Kubernetes which API group and version to use
- `kind`: declares the resource type, such as Pod, Deployment, Service
- `metadata`: contains the resource name, labels, and namespace
- `spec`: defines the desired state of the resource

---

# Declarative vs Imperative Approach

Kubernetes is mostly managed in a declarative way.

### Imperative

```bash
kubectl create deployment nginx --image=nginx
```

### Declarative

```bash
kubectl apply -f deployment.yaml
```

The declarative approach is preferred because you keep the desired state in YAML files and can version-control them.

---

# Labels and Selectors

Labels are key-value pairs used to organize resources.

```yaml
metadata:
  name: web-app
  labels:
    app: web
    tier: frontend
```

Selectors are used by Services and Deployments to find matching Pods.

```yaml
selector:
  matchLabels:
    app: web
```

---

# Example: Deployment YAML

A Deployment manages ReplicaSets and keeps your Pods running.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:latest
          ports:
            - containerPort: 80
```

Apply it with:

```bash
kubectl apply -f deployment.yaml
```

Check status:

```bash
kubectl get deployments
kubectl get pods
```

---

# Example: Service YAML

A Service exposes Pods to the network.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

Common Service types:

- `ClusterIP`: internal access only
- `NodePort`: exposed on each node
- `LoadBalancer`: exposes externally via cloud provider

---

# Common Kubernetes Commands

```bash
kubectl get pods
kubectl get deployments
kubectl get services
kubectl describe pod nginx-pod
kubectl logs nginx-pod
kubectl delete -f deployment.yaml
```

---

# Best Practices for Writing YAML

- Keep files clean and readable
- Use consistent indentation with spaces, not tabs
- Name resources clearly and consistently
- Prefer `kubectl apply` over manual edits
- Store manifests in version control
- Use labels for organization and selection

---

## Follow

YouTube: Shubham Gour Tech

Happy Learning 🚀
---
---

---

## 📝 Additional notes

- **Quote values that look like other types:** environment variable values must be strings, so write `"8080"` and `"true"`. Without quotes, YAML reads them as a number and a boolean, and the API server rejects them.
- **Validate before applying:** `kubectl apply -f file.yml --dry-run=server` asks the API server to validate the manifest without creating anything.
- **Find a field:** `kubectl explain deployment.spec.strategy` documents any field, right from your terminal.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Objects in Kubernetes](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
- [Kubernetes object management](https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/)
- [Configuration best practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [API reference](https://kubernetes.io/docs/reference/kubernetes-api/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
