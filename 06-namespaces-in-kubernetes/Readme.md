# Kubernetes Namespaces Explained  ☸️

## What You Will Learn

- Why Kubernetes Namespaces exist
- Problems solved by Namespaces
- Resource isolation
- Default Kubernetes Namespaces
- Creating and managing Namespaces
- Creating Pods inside a Namespace
- Best practices used in production

---

# Why Do We Need Namespaces?

Imagine a company with one Kubernetes cluster shared by multiple teams.

<img width="1117" height="553" alt="Screenshot 2026-07-19 at 10 30 54 AM" src="https://github.com/user-attachments/assets/104ecbff-d154-4608-be48-16526026f354" />

Every team creates resources like Pods, Deployments, Services, ConfigMaps, and Secrets.

Without Namespaces, everything would exist together, making the cluster difficult to manage.

---

# The Problem

```text
Development
  nginx
  webapp
  frontend

Testing
  nginx
  webapp
  frontend

Production
  nginx
  webapp
  frontend
```

Namespaces logically isolate resources so teams can work independently.

---

# Apartment Analogy

Think of a Kubernetes Cluster as an apartment building.

```text
Apartment Building (Cluster)
├── Apartment A (Development)
├── Apartment B (Testing)
└── Apartment C (Production)
```

Each apartment has its own resources, just like each Namespace.

---

# Namespace Structure

```text
Cluster
├── dev
│   ├── Pods
│   ├── Services
│   └── Deployments
├── test
│   ├── Pods
│   ├── Services
│   └── Deployments
└── prod
    ├── Pods
    ├── Services
    └── Deployments
```

---

# Namespace Scoped Resources

- Pods
- Deployments
- ReplicaSets
- Services
- ConfigMaps
- Secrets
- Jobs
- CronJobs
- Ingress
- PersistentVolumeClaims (PVCs)

---

# Cluster-Wide Resources

- Nodes
- Namespaces
- PersistentVolumes (PV)
- StorageClasses
- ClusterRoles
- ClusterRoleBindings

---

# Default Kubernetes Namespaces

```bash
kubectl get ns
```

| Namespace | Purpose |
|-----------|---------|
| default | Used when no Namespace is specified |
| kube-system | Kubernetes system components |
| kube-public | Public cluster information |
| kube-node-lease | Node heartbeat information |

Explore system components:

```bash
kubectl get pods -n kube-system
```

---

# Create a Namespace

```bash
kubectl create namespace development
```

or

```bash
kubectl create ns development
```

List Namespaces:

```bash
kubectl get ns
```

Delete:

```bash
kubectl delete namespace development
```

---

# Create a Namespace Using YAML

```yaml
apiVersion: v1
kind: Namespace

metadata:
  name: development
```

```bash
kubectl apply -f namespace.yaml
```

---

# Create a Pod Inside a Namespace

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: nginx
  namespace: development

spec:
  containers:
    - name: nginx
      image: nginx
      ports:
        - containerPort: 80
```

Apply:

```bash
kubectl apply -f pod.yaml
```

Verify:

```bash
kubectl get pods -n development
kubectl get pods -A
```

---

# Can Two Namespaces Have the Same Pod Name?

Yes.

```text
development
└── nginx

testing
└── nginx
```

These Pods do not conflict because they exist in different Namespaces.

---

# What Happens When You Delete a Namespace?

```bash
kubectl delete namespace development
```

Everything inside the Namespace is deleted, including Pods, Deployments, Services, ConfigMaps, Secrets, Jobs, and PVCs.

---

# Best Practices

- Create separate Namespaces for Development, Testing, Staging, and Production.
- Avoid deploying applications in the `default` Namespace.
- Use meaningful Namespace names.
- Organize related resources together.
- Use labels for better organization.

---

# Key Takeaways

- A Namespace is a logical partition inside a Kubernetes cluster.
- It isolates resources between teams and applications.
- Resources can have identical names in different Namespaces.
- Most application resources are Namespace scoped.
- Nodes, StorageClasses, and PersistentVolumes are cluster-wide resources.
---
---

---

## 📝 Additional notes

- **Stop typing `-n`:** set a default namespace for your current context with `kubectl config set-context --current --namespace=<name>`.
- **Fair sharing:** a `ResourceQuota` caps total usage in a namespace, and a `LimitRange` sets default and maximum values for each container.
- **Namespaces aren't a security boundary on their own:** by default, Pods in different namespaces can still talk to each other. Use RBAC (module 30) and NetworkPolicies (module 34) for isolation.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Share a cluster with namespaces](https://kubernetes.io/docs/tasks/administer-cluster/namespaces/)
- [Resource quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Limit ranges](https://kubernetes.io/docs/concepts/policy/limit-range/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
