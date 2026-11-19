# Kubernetes Masterclass: kubectl Explained

> The complete beginner-to-intermediate guide to the most important `kubectl` commands used by DevOps Engineers, Platform Engineers, SREs, and Kubernetes Administrators.

---

# 📖 What is kubectl?

`kubectl` is the command-line tool used to interact with a Kubernetes cluster.

Think of it as a **remote control for Kubernetes**.

With kubectl, you can:

- View cluster resources
- Deploy applications
- Troubleshoot issues
- Access containers
- Modify configurations
- Delete workloads

Without kubectl, managing Kubernetes would be nearly impossible.

---

# 🏗️ How kubectl Communicates with Kubernetes

```text
          kubectl
              |
              |
              v
      Kubernetes API Server
              |
    ----------------------
    |          |         |
    v          v         v
  Pods    Deployments  Services
```

Whenever you execute a command, kubectl sends a request to the Kubernetes API Server.

The API Server validates the request and updates the cluster state.

---

# ✅ Verify Cluster Connectivity

Check whether kubectl can communicate with your cluster.

```bash
kubectl cluster-info
```

Example:

```bash
Kubernetes control plane is running at https://127.0.0.1:6443
```

View available nodes:

```bash
kubectl get nodes
```

Example:

```bash
NAME           STATUS   ROLES
master-node    Ready    control-plane
worker-node    Ready
```

---

# 1️⃣ kubectl get

Used to list Kubernetes resources.

## View Pods

```bash
kubectl get pods
```

Example:

```bash
NAME                     READY   STATUS
nginx-78f5d695bd-abcde   1/1     Running
```

## Detailed Pod Information

```bash
kubectl get pods -o wide
```

Shows:

- Pod IP
- Node Name
- Additional Scheduling Information

## View Deployments

```bash
kubectl get deployments
```

## View Services

```bash
kubectl get svc
```

## View Nodes

```bash
kubectl get nodes
```

💡 First command used during troubleshooting.

---

# 2️⃣ kubectl describe

Provides detailed information about a resource.

```bash
kubectl describe pod <pod-name>
```

Example:

```bash
kubectl describe pod nginx-78f5d695bd-abcde
```

Useful Information:

- Labels
- Annotations
- Container Status
- Mounted Volumes
- Events
- Scheduling Details

## Why Use It?

If a Pod is stuck in:

```text
Pending
CrashLoopBackOff
ImagePullBackOff
```

The Events section usually reveals the cause.

---

# 3️⃣ kubectl logs

Displays container logs.

```bash
kubectl logs <pod-name>
```

Example:

```bash
kubectl logs nginx-78f5d695bd-abcde
```

Output:

```text
Starting nginx...
Listening on port 80
```

## Follow Logs in Real-Time

```bash
kubectl logs -f nginx-78f5d695bd-abcde
```

Equivalent to:

```bash
tail -f logfile.log
```

## Multiple Containers

```bash
kubectl logs <pod-name> -c <container-name>
```

---

# 4️⃣ kubectl exec

Access a running container.

```bash
kubectl exec -it nginx-pod -- bash
```

If bash is unavailable:

```bash
kubectl exec -it nginx-pod -- sh
```

## Useful Commands

```bash
ls
pwd
hostname
ps
```

## Real-World Use Cases

- Verify files
- Check application configuration
- Test connectivity
- Debug issues inside containers

---

# 5️⃣ kubectl edit

Modify resources directly from the terminal.

```bash
kubectl edit deployment nginx
```

Example:

Before:

```yaml
replicas: 1
```

After:

```yaml
replicas: 3
```

Save and exit.

Kubernetes automatically applies the change.

⚠️ Avoid frequent use in production GitOps environments.

---

# 6️⃣ kubectl apply

The preferred way to create or update Kubernetes resources.

## deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: my-nginx

spec:
  replicas: 2

  selector:
    matchLabels:
      app: nginx

  template:
    metadata:
      labels:
        app: nginx

    spec:
      containers:
      - name: nginx
        image: nginx
```

Deploy:

```bash
kubectl apply -f deployment.yaml
```

Verify:

```bash
kubectl get deployments
```

💡 Most commonly used command in real-world Kubernetes projects.

---

# 7️⃣ kubectl delete

Remove resources from the cluster.

## Delete Pod

```bash
kubectl delete pod nginx-pod
```

## Delete Deployment

```bash
kubectl delete deployment nginx
```

## Delete Resources Defined in YAML

```bash
kubectl delete -f deployment.yaml
```

Always verify before deleting production workloads.

---

# 🔥 Real-World Troubleshooting Workflow

When an application fails:

### Step 1

```bash
kubectl get pods
```

Find problematic Pod.

### Step 2

```bash
kubectl describe pod <pod-name>
```

Check Events.

### Step 3

```bash
kubectl logs <pod-name>
```

Review application logs.

### Step 4

```bash
kubectl exec -it <pod-name> -- sh
```

Debug inside container.

### Step 5

```bash
kubectl apply -f deployment.yaml
```

Deploy fixes.

### Step 6

```bash
kubectl delete pod <pod-name>
```

Recreate workload if required.

---

# 📌 kubectl Cheat Sheet

| Command | Purpose |
|----------|----------|
| kubectl get | List resources |
| kubectl describe | Detailed resource information |
| kubectl logs | View application logs |
| kubectl exec | Access running containers |
| kubectl edit | Modify resources |
| kubectl apply | Create/Update resources |
| kubectl delete | Remove resources |

---

# 🎯 Key Takeaways

By mastering these seven commands, you can perform nearly 80% of day-to-day Kubernetes operations:

✅ View Resources

✅ Troubleshoot Applications

✅ Access Containers

✅ Deploy Workloads

✅ Modify Configurations

✅ Delete Resources

---

# 📚 Next Steps

After mastering kubectl, continue with:

1. Pods Deep Dive
2. Deployments
3. Services
4. ConfigMaps
5. Secrets
6. Ingress
7. StatefulSets
8. Helm
9. Monitoring & Logging
10. Production Kubernetes

---

⭐ If this repository helped you, consider giving it a star and sharing it with others learning Kubernetes.
---
---

---

## 📝 Additional notes

- **Crashed container logs:** `kubectl logs <pod> --previous` shows logs from the last crashed container. This is often the only place the error appears when a Pod is in `CrashLoopBackOff`.
- **Generate YAML instead of writing it:** `kubectl create deployment web --image=nginx --dry-run=client -o yaml` prints a starter manifest and creates nothing.
- **Preview a change:** `kubectl diff -f file.yml` shows what `apply` would change.
- **Debug minimal images:** if an image has no shell, `kubectl debug -it <pod> --image=busybox --target=<container>` attaches a temporary debug container.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [kubectl overview](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl quick reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/)
- [Debug running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
