# StatefulSets Explained with Databases ☸️

 



> **Scope:** This lesson intentionally does **not** cover PersistentVolumes, PersistentVolumeClaims, StorageClasses, or `volumeClaimTemplates`. Storage is a separate Kubernetes topic.

---

# 1. Stateless vs Stateful

## Stateless

```text
                 Users
                   |
                   v
               Service
                   |
          +--------+--------+
          |        |        |
          v        v        v
        Pod A    Pod B    Pod C
```

Pods are generally interchangeable. If one disappears, another can take its place.

Typical examples:
- Web applications
- REST APIs
- Frontends
- Stateless microservices

## Stateful

A stateful application may care about:

- Identity
- Relationships between instances
- Predictable network identity
- Lifecycle
- Ordering

Databases are a common example.

---

# 2. Why Not Just Use a Deployment?

Deployment:

```text
Deployment
    |
 +-- Pod
 +-- Pod
 +-- Pod
```

StatefulSet:

```text
StatefulSet
    |
 +-- mysql-0
 +-- mysql-1
 +-- mysql-2
```

A Deployment is generally suited to interchangeable replicas.

A StatefulSet is designed for workloads where individual Pod identity and predictable lifecycle behavior matter.

---

# 3. What Is a StatefulSet?

A StatefulSet is a Kubernetes workload controller designed for applications requiring **stable identity and predictable lifecycle behavior**.

Mental model:

> **Deployment → interchangeable Pods**

> **StatefulSet → Pods with stable identity**

---

# 4. StatefulSet Architecture

```text
                    StatefulSet
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
       mysql-0        mysql-1        mysql-2
```

If scaled to five:

```text
mysql-0
mysql-1
mysql-2
mysql-3
mysql-4
```

The Pods have predictable ordinal identities.

---

# 5. StatefulSet YAML

Create `mysql-statefulset.yaml`:

```yaml
apiVersion: apps/v1
kind: StatefulSet

metadata:
  name: mysql

spec:
  serviceName: mysql

  replicas: 3

  selector:
    matchLabels:
      app: mysql

  template:
    metadata:
      labels:
        app: mysql

    spec:
      containers:
        - name: mysql
          image: mysql:8.0

          ports:
            - containerPort: 3306

          env:
            - name: MYSQL_ROOT_PASSWORD
              value: rootpassword
```

## YAML Breakdown

### apiVersion

```yaml
apiVersion: apps/v1
```

StatefulSet belongs to the `apps/v1` API group.

### kind

```yaml
kind: StatefulSet
```

Tells Kubernetes to create a StatefulSet.

### metadata

```yaml
metadata:
  name: mysql
```

Defines the StatefulSet name and becomes the base for Pod names.

### serviceName

```yaml
serviceName: mysql
```

Identifies the Service associated with the StatefulSet.

### replicas

```yaml
replicas: 3
```

Creates:

```text
mysql-0
mysql-1
mysql-2
```

### selector

```yaml
selector:
  matchLabels:
    app: mysql
```

Identifies Pods managed by the StatefulSet.

### template

Defines the Pod blueprint.

### labels

```yaml
labels:
  app: mysql
```

Must match the StatefulSet selector.

---

# 6. Headless Service

Create `mysql-service.yaml`:

```yaml
apiVersion: v1
kind: Service

metadata:
  name: mysql

spec:
  clusterIP: None

  selector:
    app: mysql

  ports:
    - port: 3306
      targetPort: 3306
```

The important line is:

```yaml
clusterIP: None
```

This makes the Service headless.

---

# 7. Create the Service

```bash
kubectl apply -f mysql-service.yaml
kubectl get svc
```

The Service should show:

```text
CLUSTER-IP   None
```

A Headless Service is commonly used with StatefulSets to provide DNS-based discovery of individual Pods.

---

# 8. Create the StatefulSet

```bash
kubectl apply -f mysql-statefulset.yaml
```

Verify:

```bash
kubectl get sts
kubectl get pods
```

Expected naming pattern:

```text
mysql-0
mysql-1
mysql-2
```

---

# 9. Watch Pod Creation

```bash
kubectl get pods -w
```

StatefulSets provide ordered lifecycle behavior.

Conceptually:

```text
mysql-0
   ↓
mysql-1
   ↓
mysql-2
```

---

# 10. Delete a StatefulSet Pod

```bash
kubectl delete pod mysql-1
```

Watch:

```bash
kubectl get pods -w
```

The StatefulSet recreates the expected identity:

```text
mysql-1
```

The important point is that the replacement keeps the StatefulSet identity.

---

# 11. Scale StatefulSet

Scale to five:

```bash
kubectl scale statefulset mysql --replicas=5
```

Verify:

```bash
kubectl get pods
```

Expected:

```text
mysql-0
mysql-1
mysql-2
mysql-3
mysql-4
```

Scale down:

```bash
kubectl scale statefulset mysql --replicas=2
```

Verify:

```bash
kubectl get pods
```

Expected:

```text
mysql-0
mysql-1
```

---

# 12. Stable Network Identity

With a Headless Service named `mysql`, StatefulSet Pods can have predictable DNS identities such as:

```text
mysql-0.mysql
mysql-1.mysql
mysql-2.mysql
```

The fully qualified DNS name also includes the namespace and cluster DNS suffix.

The key idea:

> **StatefulSet + Headless Service can provide predictable network identities for individual Pods.**

---

# 13. Test DNS

Create a temporary Pod:

```bash
kubectl run dns-test   --image=busybox:1.36   --restart=Never   -- sleep 3600
```

Enter it:

```bash
kubectl exec -it dns-test -- sh
```

Test:

```bash
nslookup mysql-0.mysql
nslookup mysql-1.mysql
nslookup mysql-2.mysql
```

Exit:

```bash
exit
```

Delete:

```bash
kubectl delete pod dns-test
```

---

# 14. StatefulSet vs Deployment

| Feature | Deployment | StatefulSet |
|---|---|---|
| Typical use | Stateless applications | Stateful applications |
| Replica support | Yes | Yes |
| Stable Pod names | No | Yes |
| Predictable identity | No | Yes |
| Ordered lifecycle | Not the core behavior | Yes |
| Stable per-Pod network identity | Not inherently | Supported with Headless Service |
| Common examples | APIs, web apps | Databases, clustered systems |

---

# 15. Production Examples

StatefulSets can be useful for applications where individual instance identity matters.

Examples:

- MySQL
- PostgreSQL
- MongoDB
- Kafka
- ZooKeeper
- Elasticsearch

The important question is not simply:

> "Is it a database?"

Instead ask:

> **Does the workload require stable identity and predictable lifecycle behavior?**

---

# 16. Important: StatefulSet Does NOT Solve Everything

Creating:

```text
StatefulSet
    |
    +-- mysql-0
    +-- mysql-1
    +-- mysql-2
```

does **not** automatically create a production-ready database cluster.

StatefulSet does not automatically provide:

- Database replication
- Leader election
- Automatic database failover
- Backups
- Disaster recovery
- Data consistency
- Database-specific clustering

StatefulSet provides Kubernetes-level workload and identity primitives.

The database software is responsible for database-specific behavior.

---

# 17. Storage Is a Separate Topic

This lesson intentionally does not cover:

- PersistentVolumes
- PersistentVolumeClaims
- StorageClasses
- `volumeClaimTemplates`

For this lesson, focus on:

```text
StatefulSet
    ↓
Stable identity
    ↓
Predictable lifecycle
    ↓
Stable network identity
```

---

# 18. Pod Management Policy

The default behavior is:

```yaml
podManagementPolicy: OrderedReady
```

Another option is:

```yaml
podManagementPolicy: Parallel
```

### OrderedReady

Pods follow ordered lifecycle behavior.

### Parallel

Pods can be created or terminated without waiting for the previous Pod in the sequence.

Use `Parallel` when strict ordering is not required by the application.

---

# 19. Inspect the StatefulSet

```bash
kubectl describe statefulset mysql
```

or:

```bash
kubectl describe sts mysql
```

Inspect the stored resource:

```bash
kubectl get sts mysql -o yaml
```

Look at:

- Replicas
- Service Name
- Selector
- Pod Template
- Events

---

# 20. Troubleshooting

Start with:

```bash
kubectl get sts
kubectl get pods
```

Then:

```bash
kubectl describe sts mysql
kubectl describe pod mysql-0
kubectl get events
kubectl get svc
```

The troubleshooting principle:

> **Inspect the Kubernetes state before changing your YAML.**

---

# 21. Common Mistakes

### Mistake 1

Thinking StatefulSet is simply a Deployment with numbered Pods.

Stable identity and predictable lifecycle behavior are the important concepts.

### Mistake 2

Thinking StatefulSet automatically provides database replication.

It does not.

### Mistake 3

Thinking StatefulSet automatically provides backups.

It does not.

### Mistake 4

Forgetting the Headless Service when stable DNS identity is required.

### Mistake 5

Using StatefulSet for every application.

If the application is stateless, Deployment is usually simpler.

---

# 22. Production Architecture

```text
                 Application
                      |
                      v
               Database Service
                      |
        +-------------+-------------+
        |             |             |
        v             v             v
     mysql-0       mysql-1       mysql-2
```

StatefulSet provides Kubernetes-level identity and lifecycle behavior.

The database software itself handles database-specific clustering and replication.

---

# 23. StatefulSet vs Other Workloads

```text
Deployment
    ↓
"Keep N interchangeable Pods running."


DaemonSet
    ↓
"Run a Pod on every eligible node."


Job
    ↓
"Run this task until it completes."


CronJob
    ↓
"Run this task on a schedule."


StatefulSet
    ↓
"Run Pods whose identity and lifecycle matter."
```

---

# 24. Interview Questions

1. What is a StatefulSet?
2. How is StatefulSet different from Deployment?
3. Why do StatefulSet Pods have names like `mysql-0`?
4. What happens when `mysql-1` is deleted?
5. What is a Headless Service?
6. Why is `clusterIP: None` used?
7. Does StatefulSet automatically make MySQL highly available?
8. Does StatefulSet automatically provide database replication?
9. When should you use a Deployment instead?
10. Why is stable Pod identity useful for stateful applications?

---

# 25. Final Mental Model

## Deployment

```text
Deployment
    |
    +-- Pod
    +-- Pod
    +-- Pod

Pods are interchangeable.
```

## StatefulSet

```text
StatefulSet
    |
    +-- mysql-0
    +-- mysql-1
    +-- mysql-2

Pods have stable identities.
```

---

# 🧠 Five Things to Remember

### 1. Stable Identity

```text
mysql-0
mysql-1
mysql-2
```

### 2. Predictable Naming

StatefulSet Pod names follow a predictable ordinal pattern.

### 3. Ordered Lifecycle

StatefulSets provide predictable creation, scaling and termination behavior.

### 4. Stable Network Identity

With a Headless Service:

```text
mysql-0.mysql
mysql-1.mysql
mysql-2.mysql
```

### 5. StatefulSet ≠ Complete Database Solution

StatefulSet provides Kubernetes workload primitives.

Database replication, failover, backups and disaster recovery are separate concerns.

---

# 🚀 Hands-On Command Cheat Sheet

```bash
# Check nodes
kubectl get nodes

# Create Service
kubectl apply -f mysql-service.yaml

# Create StatefulSet
kubectl apply -f mysql-statefulset.yaml

# List StatefulSets
kubectl get sts

# List Pods
kubectl get pods

# Watch Pods
kubectl get pods -w

# Describe StatefulSet
kubectl describe sts mysql

# Describe Pod
kubectl describe pod mysql-0

# Scale StatefulSet
kubectl scale statefulset mysql --replicas=5

# Scale down
kubectl scale statefulset mysql --replicas=2

# Check Services
kubectl get svc

# Inspect StatefulSet YAML
kubectl get sts mysql -o yaml

# Check events
kubectl get events

# Delete a Pod
kubectl delete pod mysql-1

# Test DNS
kubectl run dns-test   --image=busybox:1.36   --restart=Never   -- sleep 3600

kubectl exec -it dns-test -- sh

nslookup mysql-0.mysql
nslookup mysql-1.mysql
nslookup mysql-2.mysql

exit

kubectl delete pod dns-test
```

---

# 📌 Final Takeaway

> **Deployment:** "I need interchangeable application replicas."

> **DaemonSet:** "I need one Pod on every eligible node."

> **Job:** "I need this task to finish."

> **CronJob:** "I need this task to run on a schedule."

> **StatefulSet:** "I need Pods with stable identity and predictable lifecycle behavior."

---

## Happy Learning! 🚀

**Shubham Gour Tech**

---

## 📝 Additional notes

- **Storage stays behind by default:** PVCs created from `volumeClaimTemplates` remain after you delete or scale down a StatefulSet. `persistentVolumeClaimRetentionPolicy` changes this behaviour.
- **Safer upgrades:** `updateStrategy.rollingUpdate.partition` updates only Pods with an ordinal at or above that number, so you can test a new version on some replicas first.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [StatefulSet basics (tutorial)](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/)
- [Run a replicated stateful application](https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
