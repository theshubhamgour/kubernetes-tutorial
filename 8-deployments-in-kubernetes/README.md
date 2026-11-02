# Kubernetes Deployments 

## 1. Introduction

Welcome back! In the previous topics, we learned about Pods, YAML, Labels, and Selectors.

Today, we will answer one important question:

> If Pods work, why do we need Deployments?

Imagine you deploy a single Nginx Pod. It works fine at first. But then:

- the Pod crashes
- traffic increases and you need more replicas
- you want to update the application without downtime

Doing all of this manually would be painful and error-prone.

This is exactly what Deployments solve.

---

## 2. The Problem with Standalone Pods

Pods are ephemeral. If a Pod is deleted, it is gone unless you recreate it manually.

A single Pod does not provide:

- self-healing
- automatic scaling
- controlled updates
- rollback support

This shows that a manually created Pod disappears unless you recreate it.

---

## 3. What Is a Deployment?

A Deployment is a higher-level Kubernetes object that describes the desired state of an application.

A Deployment declares:

- which image to run
- how many replicas to keep
- the update strategy
- labels and selectors

Kubernetes continuously works to keep the actual state matching the desired state.

### In simple words

A Deployment tells Kubernetes:

- “Run this app”
- “Keep 3 copies running”
- “If one fails, create another”
- “Update them gradually”

---

## 4. Deployment Architecture

```text
Deployment
   │
   │ manages
   ▼
ReplicaSet
   │
   │ ensures count
   ▼
Pod   Pod   Pod
```

### Relationship

- Deployment manages ReplicaSets
- ReplicaSets ensure the correct number of Pods exists
- Pods run the actual containers

This is the ownership chain you should remember.

---

## 5. Real-World Analogy

Think of a restaurant:

- Customers = requests
- Chefs = Pods
- Restaurant manager = Deployment

If a chef leaves, the manager hires another.

If business becomes busy, the manager adds more chefs.

If a new menu is introduced, the manager updates chefs one by one instead of closing the restaurant.

### Useful commands

```bash
kubectl get deployment nginx-deployment -o wide
kubectl get rs
kubectl get pods --show-labels
```

These commands help you visually see the relationship between Deployment, ReplicaSet, and Pods.

---

## 6. Deployment YAML Walkthrough

Here is a typical Deployment YAML:
```
apiVersion
kind
metadata
spec
replicas
selector
template
containers
```

### Important fields

- apiVersion: API version for the Deployment resource
- kind: Type of Kubernetes object
- metadata: Name and labels of the Deployment
- spec: Desired state of the Deployment
- replicas: Number of Pods to keep running
- selector: Tells the Deployment which Pods it manages
- template: Blueprint used to create each Pod
- strategy: How updates should happen

---

## 7. Commands used on the hands-on Demo

Create the Deployment:

```bash
kubectl apply -f deployment.yml
```

Verify it:

```bash
kubectl get deployments
kubectl get rs
kubectl get pods
```

You can also inspect details:

```bash
kubectl describe deployment nginx-deployment
```

---

## 8. Scaling

You can scale the Deployment by editing the YAML or using the CLI.

### Example

```bash
kubectl scale deployment nginx-deployment --replicas=2
kubectl get pods
```
---

## 11. Quick Questions

### Why not use Pods directly?

Because Pods do not provide self-healing, scaling, or rollout control.

### Deployment vs ReplicaSet

A Deployment manages ReplicaSets and adds rolling updates and rollback capabilities. A ReplicaSet mainly ensures the correct number of Pods exists.

### What happens when a Pod crashes?

The ReplicaSet controller notices the mismatch and creates a replacement Pod to match the desired replica count.

### What is desired state?

The configuration declared in YAML. Kubernetes continuously works to reconcile the actual state with the desired state.

### How does a rolling update work?

A new ReplicaSet is created, and Pods are replaced gradually based on `maxSurge` and `maxUnavailable` while the old ReplicaSet scales down.

---

## 12. Summary

Recap:

- Pods run containers
- ReplicaSets maintain replica count
- Deployments manage ReplicaSets and provide scaling, self-healing, rolling updates, and rollbacks

Deployments are one of the most important Kubernetes resources for running applications reliably in real-world environments.

---

## Happy Learning! 
---
---

---

## 📝 Additional notes

- **The selector is locked:** in `apps/v1`, a Deployment's `spec.selector` can't be changed after creation, and it must match the Pod template's labels.
- **Wait for a rollout:** `kubectl rollout status deployment/<name>` waits until the rollout finishes, which makes it useful in CI/CD pipelines.
- **Using an autoscaler?** Leave `spec.replicas` out of your manifest if an HPA manages it (module 28). Otherwise, every `kubectl apply` resets the replica count.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Run a stateless application](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/)
- [Workload management](https://kubernetes.io/docs/concepts/workloads/controllers/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
