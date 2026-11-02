# 🧭 DaemonSet Masterclass — Full Notes

Companion notes for the **Complete DaemonSet Masterclass** video (Kubernetes series). Everything covered on screen — concepts, YAML, and commands — is captured here for reference.

**Cluster used in this video:** minikube, 3 nodes, Docker driver

```bash
minikube delete
minikube start --driver=docker --nodes=3
```

> 3 nodes = 1 control-plane + 2 workers by default. Control-plane is tainted by default, so expect **2 DaemonSet Pods** unless a toleration is added.

---

## 0. Setup

Delete any existing cluster and start a fresh 3-node minikube cluster using the Docker driver:

```bash
minikube delete
minikube start --driver=docker --nodes=3
```

Confirm all 3 nodes are up and `Ready`:

```bash
kubectl get nodes
```

Expected output:

```
NAME           STATUS   ROLES           AGE
minikube       Ready    control-plane   1m
minikube-m02   Ready    <none>          1m
minikube-m03   Ready    <none>          1m
```

- 1 control-plane node (tainted by default — no ordinary Pods scheduled here unless a toleration is added)
- 2 worker nodes

> With this setup, `nginx-daemonset` should show a `DESIRED` count of **2** once deployed.

---

## 1. The Problem DaemonSets Solve

**Scenario:** You need a log collector running on *every node* in the cluster.

A Deployment with 3 replicas on a 3-node cluster does **not** guarantee one Pod per node:

```
Worker Node 1 -> Pod, Pod   (2 Pods)
Worker Node 2 -> Pod        (1 Pod)
Worker Node 3 -> (empty)    (0 Pods)
```

Deployments guarantee a **replica count**, not **node coverage**. If a node gets zero Pods, you have a blind spot.

### Analogy
| Real World | Kubernetes |
|---|---|
| Mall floor | Node |
| Security guard on every floor | DaemonSet Pod |
| Mall management policy | DaemonSet Controller |

New floor added → guard is automatically assigned. New node added → DaemonSet Pod is automatically scheduled.

### Definition

> A **DaemonSet** ensures one copy of a Pod runs on every eligible node in the cluster.

```
DaemonSet
   |
   +-- Node 1 -> Pod
   +-- Node 2 -> Pod
   +-- Node 3 -> Pod

Add Node 4 → DaemonSet automatically schedules a Pod on Node 4
```

### Where it's used in production
- Fluentd / Fluent Bit — log collection
- Prometheus Node Exporter — node metrics
- kube-proxy — Service networking rules
- CNI plugins (Calico, Flannel, Cilium) — pod networking
- Security agents — runtime/endpoint protection

**Key takeaway:** Deployments manage replicas. DaemonSets manage node coverage. New nodes automatically get a Pod — no manual steps.

---

## 2. Creating Your First DaemonSet

### Step 1 — Check nodes first

```bash
kubectl get nodes
```

Know your expected Pod count before deploying.

### Step 2 — daemonset.yaml

```yaml
apiVersion: apps/v1
kind: DaemonSet

metadata:
  name: nginx-daemonset

spec:
  selector:
    matchLabels:
      app: nginx-daemon

  template:
    metadata:
      labels:
        app: nginx-daemon

    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
```

| Field | Purpose |
|---|---|
| `apiVersion: apps/v1` | API group for DaemonSet resources |
| `kind: DaemonSet` | Resource type |
| `metadata.name` | Name of the DaemonSet object |
| `spec.selector` | Which Pods belong to this DaemonSet |
| `spec.template` | Pod blueprint used on every node |
| `template.metadata.labels` | **Must match** `selector.matchLabels` exactly |
| `containers` | Container(s) inside every Pod |

⚠️ **No `replicas` field exists on a DaemonSet — node count *is* the replica count.**

### Step 3 — Deploy

```bash
kubectl apply -f daemonset.yaml

kubectl get daemonsets
kubectl get ds
```

### Step 4 — Verify Pods

```bash
kubectl get pods -o wide
kubectl describe daemonset nginx-daemonset
```

Check: **Desired Number of Nodes Scheduled**, **Current Number Scheduled**, **Number Ready**.

### Step 5 — Self-healing demo

```bash
kubectl delete pod <daemonset-pod-name>
kubectl get pods -w
```

A replacement Pod is created immediately — **on the same node**.

### DaemonSet vs Deployment

| | Deployment | DaemonSet |
|---|---|---|
| Pod count controlled by | `replicas` field | Number of eligible nodes |
| New node joins | Nothing happens automatically | Pod auto-scheduled |
| Has `replicas`? | Yes | **No** |
| Use case | Apps, APIs, microservices | Node-level agents |

### Common beginner mistakes
- Adding a `replicas` field (ignored — DaemonSets don't use it)
- Selector and Pod labels don't match → validation error
- Editing Pods directly instead of the DaemonSet spec
- Forgetting to check `kubectl get nodes` first

---

## 3. Production Use Cases & Advanced Scheduling

| Use Case | Tool(s) | Why it must be a DaemonSet |
|---|---|---|
| Log collection | Fluent Bit, Fluentd | Reads logs local to each node |
| Monitoring | Prometheus Node Exporter | Exposes local CPU/memory/disk/network metrics |
| Networking (CNI) | Calico, Flannel, Cilium | Pod networking is per-node |
| Service networking | kube-proxy | Configures local iptables/IPVS rules |

```bash
kubectl get ds -A
kubectl describe ds <daemonset-name> -n <namespace>
kubectl get pods -A -o wide
```

### Restrict to specific nodes — `nodeSelector`

```bash
kubectl get nodes --show-labels
kubectl label node <node-name> disktype=ssd
```

```yaml
spec:
  template:
    spec:
      nodeSelector:
        disktype: ssd
```

Only nodes labeled `disktype=ssd` receive a Pod.

### Schedule on control-plane nodes — Tolerations

```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```

Required because control-plane nodes are tainted against ordinary workloads by default. Common for monitoring/networking DaemonSets.

### Best practices
- Keep containers lightweight — they multiply across every node
- Always set resource requests/limits
- Use `nodeSelector` when you don't need every node
- Avoid unnecessary privileged containers
- Monitor DaemonSet health continuously

---

## 4. Updates, Rollouts & DaemonSet vs Deployment

### Deployment vs DaemonSet placement

```
Deployment (3 replicas)          DaemonSet
Node 1 -> Pod                    Node 1 -> Pod
Node 2 -> Pod, Pod                Node 2 -> Pod
Node 3 -> (empty)                Node 3 -> Pod
```

### When to use which

| Use a Deployment for | Use a DaemonSet for |
|---|---|
| Web apps, REST APIs | Log collection agents |
| Microservices | Monitoring agents |
| Frontend apps | Networking (CNI, kube-proxy) |
| | Storage / security agents |

### Updating a DaemonSet

```yaml
containers:
- name: nginx
  image: nginx:1.28   # was 1.27
```

```bash
kubectl apply -f daemonset.yaml

kubectl rollout status daemonset/nginx-daemonset
kubectl get pods -w
```

Updates roll out **gradually, node by node** — not all at once — to avoid cluster-wide outages (critical for networking DaemonSets).

Verify the new image:

```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].image}'
```

### Deleting a DaemonSet

```bash
kubectl delete daemonset nginx-daemonset

kubectl get ds
kubectl get pods
```

All Pods across all nodes are removed automatically.

---

## 5. Hands-On Lab (Quick Sequence)

```bash
# 1. Verify
kubectl get ds
kubectl describe ds nginx-daemonset

# 2. Verify placement
kubectl get pods -o wide
kubectl get nodes

# 3. Delete + watch self-heal
kubectl delete pod <daemonset-pod-name>
kubectl get pods -w

# 4. Update image
kubectl apply -f daemonset.yaml
kubectl rollout status daemonset/nginx-daemonset
kubectl get pods -w
```

---

## 6. Troubleshooting

| Problem | Check |
|---|---|
| Pods not created | `kubectl describe ds <name>` and `kubectl get events` |
| Wrong node placement | `kubectl get nodes --show-labels` vs `nodeSelector` in YAML |
| Missing from control-plane | Verify `tolerations` block is present |

### Production tips
- Lightweight containers, always set resource limits
- Use explicit image tags, never `:latest`
- Monitor DaemonSet health — don't assume silence = success
- Test changes in non-prod first, especially for CNI/kube-proxy DaemonSets

---

## 7. Cheat Sheet

```bash
# Cluster setup
minikube delete
minikube start --driver=docker --nodes=3

# Core DaemonSet commands
kubectl get nodes
kubectl apply -f daemonset.yaml
kubectl get ds
kubectl get daemonsets
kubectl get pods -o wide
kubectl describe daemonset <name>
kubectl delete pod <pod-name>
kubectl get pods -w
kubectl rollout status daemonset/<name>
kubectl delete daemonset <name>

# All namespaces
kubectl get ds -A
kubectl get pods -A -o wide

# Node labels / scheduling
kubectl get nodes --show-labels
kubectl label node <node-name> <key>=<value>

# Troubleshooting
kubectl get events
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].image}'
```

---

## 8. Interview Questions

1. What problem does a DaemonSet solve that a Deployment cannot?
2. Why doesn't a DaemonSet have a `replicas` field?
3. What happens automatically when a new node joins the cluster?
4. Give four real production use cases for a DaemonSet.
5. How do you update a DaemonSet — all at once or gradually?
6. How would you troubleshoot a DaemonSet not scheduling on all expected nodes?
7. How do you restrict a DaemonSet to a subset of nodes?
8. How do you allow a DaemonSet to run on the control-plane node?

---

## 🧠 Final Mental Model

- **Deployment** → desired number of Pods, freely scheduled
- **ReplicaSet** → maintains that Pod count (usually managed by a Deployment)
- **DaemonSet** → exactly one Pod per eligible node, automatic as nodes join/leave

> Use Deployments for your applications. Use DaemonSets for node-level infrastructure — logging, monitoring, networking, and security.
---
---

---

## 📝 Additional notes

- **Controlling updates:** the default `updateStrategy` is `RollingUpdate`. Use `OnDelete` when you want a Pod replaced only after you delete it yourself, for example while draining nodes one at a time.
- **Draining nodes:** `kubectl drain` won't proceed past DaemonSet Pods unless you add `--ignore-daemonsets`.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [Perform a rolling update on a DaemonSet](https://kubernetes.io/docs/tasks/manage-daemon/update-daemon-set/)
- [Safely drain a node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
