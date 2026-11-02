# Persistent Volume (PV) in Kubernetes

## Overview

A PersistentVolume is a cluster-level storage resource that exists independently of a single Pod. It represents storage made available to Kubernetes and can be consumed by workloads through a PersistentVolumeClaim.

A normal volume defined inside a Pod is tied to the Pod lifecycle. A PV is different because it is a separate Kubernetes object with its own lifecycle.

---

## Why PV is Required

Container filesystems are ephemeral. If a Pod restarts or is deleted, data stored inside the container filesystem is lost.

This is why Kubernetes provides several storage options:

- `emptyDir`: tied to the Pod lifecycle
- `hostPath`: tied to a node path
- `PersistentVolume`: cluster-level storage with a lifecycle independent of the Pod

`emptyDir` and `hostPath` are useful for temporary or local storage, but they are not enough for durable application data.

---

## Key Concept

```text
Pod → PVC → PV → underlying storage
```

- `Pod`: workload that needs storage
- `PVC`: request for storage
- `PV`: actual storage resource available in the cluster
- `underlying storage`: local, network, or cloud storage backend

The Pod does not mount a PV directly. It mounts a PVC, and Kubernetes binds that claim to a suitable PV.

---

## PV vs Regular Volume

### Regular volume

A volume is created as part of the Pod definition.

Example:

- `emptyDir`
- `hostPath`
- configMap
- secret

These volumes are tightly coupled to the Pod and usually do not survive Pod deletion.

### PersistentVolume

A PV is not part of the Pod specification. It is created as a standalone resource in the cluster.

This makes it suitable for data that must survive Pod replacement, restart, or rescheduling.

---

## What a PV Actually Represents

A PV object does not store the data itself. It describes the storage resource.

The actual data lives in an underlying storage system such as:

- local filesystem
- network-attached storage
- cloud disk

A PV is the Kubernetes abstraction layer over that storage.

---

## Static Provisioning

In this lesson, the PV is created manually.

This is called static provisioning.

Later, Kubernetes can also create storage automatically through StorageClasses. That is known as dynamic provisioning.

---

## Example: Minikube Demo

A directory is created on the Minikube node:

```bash
minikube ssh -- sudo mkdir -p /data/pv-demo
```

Then a PV is created using `hostPath`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: demo-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /data/pv-demo
    type: Directory
```

### Important fields

- `capacity.storage`: total storage available
- `volumeMode`: filesystem mode
- `accessModes`: access policy for the volume
- `persistentVolumeReclaimPolicy`: what to do after the PVC is deleted
- `storageClassName`: class assigned to the PV
- `hostPath`: node path used as the backing storage

Apply:

```bash
kubectl apply -f persistent-volume.yaml
kubectl get pv
```

Status before binding:

```text
Available
```

This means the PV exists and is ready to be claimed by a suitable PVC, but it is not yet used.

---

## PV Claim Workflow

The normal flow is:

1. Create PV
2. Create PVC
3. Bind PVC to PV
4. Mount PVC in a Pod
5. Use the mounted storage

Example PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual
```

Apply:

```bash
kubectl apply -f demo-pvc.yaml
kubectl get pvc
kubectl get pv
```

When matched, the PV status becomes:

```text
Bound
```

---

## Pod Usage

A Pod consumes the PVC, not the PV directly.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pv-demo-pod
spec:
  containers:
    - name: app
      image: busybox
      command:
        - sh
        - -c
        - sleep 3600
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: demo-pvc
```

Write data:

```bash
kubectl exec pv-demo-pod -- sh -c 'echo "Hello from PersistentVolume" > /data/message.txt'
```

Check the node storage:

```bash
minikube ssh -- sudo cat /data/pv-demo/message.txt
```

This verifies that the Pod is writing to the storage behind the PV.

---

## Life Cycle States of a PV

A PersistentVolume can be in the following states:

- `Available`: ready and not yet bound
- `Bound`: matched to a PVC
- `Released`: claim removed, but reclaim is not complete
- `Failed`: reclaim failed

This is important for troubleshooting and understanding what happens after a PVC is deleted.

---

## Reclaim Policy

The reclaim policy decides what happens to the PV and its backing storage after the claim is deleted.

### Retain

```yaml
persistentVolumeReclaimPolicy: Retain
```

- PV stays in `Released` state
- underlying storage is kept
- manual cleanup or reuse is required

### Delete

```yaml
persistentVolumeReclaimPolicy: Delete
```

- PV is deleted
- underlying storage may also be deleted if the backend supports it

The choice depends on storage backend behavior and data protection requirements.

---

## Proof of PV Behavior

A Pod is deleted:

```bash
kubectl delete pod pv-demo-pod
```

Then the Pod is recreated and the file is checked again:

```bash
kubectl exec pv-demo-pod -- cat /data/message.txt
```

The data remains because the storage is not tied to the original Pod lifecycle.

This is the core value of PersistentVolumes.

---

## Delete PVC and Observe Release

```bash
kubectl delete pvc demo-pvc
kubectl get pv
```

With `Retain`, the PV moves to `Released` instead of becoming immediately reusable.

The storage still exists on the node:

```bash
minikube ssh -- sudo cat /data/pv-demo/message.txt
```

This confirms that the data survives even after the PVC is deleted.

---

## Important Limitation of hostPath PVs

The demo uses `hostPath` because it is simple to show on Minikube.

However, this is not a production-grade storage pattern.

A `hostPath`-based PV is still tied to a specific node path. If the workload moves to another node, the same directory may not exist there.

This makes the volume node-dependent.

For real environments, Kubernetes usually uses network or cloud-backed storage systems that support multi-node availability and better resilience.

---

## PV is Not the Same as Cloud Storage

A PV is a Kubernetes abstraction. It does not automatically mean AWS EBS, Azure Disk, or GCP PD.

The underlying storage may be:

- local
- network-based
- cloud-managed

The PV simply represents that storage to Kubernetes.

---

## Static vs Dynamic Provisioning

### Static provisioning

Administrator creates the PV manually.

### Dynamic provisioning

PVC requests storage and a StorageClass triggers automatic creation of PVs by the storage backend.

This is useful when storage needs to be provisioned on demand.

---

## Comparison Summary

| Storage Type | Scope | Lifecycle | Typical Use |
| --- | --- | --- | --- |
| Container filesystem | single container | tied to container | temporary files |
| `emptyDir` | Pod | tied to Pod | cache/temp data |
| `hostPath` | node path | tied to node | local testing |
| `PersistentVolume` | cluster | independent of Pod | durable app data |

---

## Key Takeaways

- A PersistentVolume is a storage resource in the cluster.
- It is independent of the lifetime of a specific Pod.
- A Pod uses a PVC, not a PV directly.
- PVs can survive Pod recreation and Pod deletion.
- Reclaim policy controls what happens when the PVC is deleted.
- PVs are an abstraction; the real backend can be local or cloud storage.

---

## One-Line Definition

A PersistentVolume is a Kubernetes storage resource whose lifecycle is independent of an individual Pod.

---

## Next Topic

- PersistentVolumeClaim in detail
- StorageClass and dynamic provisioning
- binding behavior and access modes

---

## 📝 Additional notes

- **Scope:** a PV is a cluster-wide resource with no namespace, while a PVC belongs to a namespace.
- **Access modes:** `ReadWriteOnce` allows mounting by one node, `ReadWriteMany` by many nodes (if the storage supports it), and `ReadWriteOncePod` by a single Pod.
- **Reusing a `Released` PV:** with `Retain`, a PV stays `Released` after its PVC is deleted and won't bind again by itself. After you check or clean the data, an admin must remove its `spec.claimRef`.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Access modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
- [Deploying WordPress and MySQL with persistent volumes](https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
