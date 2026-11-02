# PersistentVolumeClaim (PVC) - Reference Notes

## 1. Definition

A PVC is a request for storage made by a user or application in Kubernetes.

- PV = provides storage
- PVC = requests storage
- Pod = uses the storage through the PVC

```text
Pod -> PVC -> PV -> underlying storage
```

---

## 2. Why PVC is needed

A Pod should not care about:

- which disk is used
- which node has the storage
- which storage backend is behind it

It only says:

"I need persistent storage."

That request is represented by a PVC.

---

## 3. PV vs PVC

### PersistentVolume (PV)

- cluster-level actual storage resource
- available to the cluster
- represents storage capacity

### PersistentVolumeClaim (PVC)

- user/app request for storage
- binds to a suitable PV
- used by Pods

```text
PV     -> provides
PVC    -> requests
Pod    -> consumes
```

---

## 4. Example flow

We have:

- PV: `demo-pv`
- Capacity: `1Gi`
- StorageClass: `manual`

Create PVC:

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
```

Output:

```text
NAME       STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS

demo-pvc   Bound    demo-pv   1Gi        RWO            manual
```

`Bound` means the PVC is matched with a suitable PV.

---

## 5. Key PVC fields

### accessModes

```yaml
accessModes:
  - ReadWriteOnce
```

- tells Kubernetes the access pattern required
- `ReadWriteOnce` = writable by one node

### resources.requests.storage

```yaml
resources:
  requests:
    storage: 1Gi
```

- amount of storage requested
- matches PV capacity requirements

### storageClassName

```yaml
storageClassName: manual
```

- request is for a specific storage class
- PV and PVC must be compatible

### volumeMode

```yaml
volumeMode: Filesystem
```

- `Filesystem` = normal mounted file system (default)
- `Block` = raw block device

### volumeName

```yaml
volumeName: demo-pv
```

- binds to a specific PV

### selector

```yaml
selector:
  matchLabels:
    environment: prod
```

- filters candidate PVs using labels

---

## 6. Matching rule

Kubernetes looks for a PV that satisfies:

- requested storage size
- access mode
- storage class
- any selector rules

If no match is found:

```text
PVC = Pending
```

If a matching PV is later created, it can become `Bound`.

---

## 7. One-to-one binding

A PVC binds to only one PV.

```text
PVC -> PV
```

One PV cannot be bound to multiple PVCs at the same time.

---

## 8. Using PVC in a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-demo-pod
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: demo-pvc
```

Important part:

```yaml
persistentVolumeClaim:
  claimName: demo-pvc
```

This tells the Pod to use the storage claimed by `demo-pvc`.

---

## 9. Data persistence demo

Write data:

```bash
kubectl exec pvc-demo-pod -- sh -c 'echo "Hello from PVC" > /data/message.txt'
```

Read data:

```bash
kubectl exec pvc-demo-pod -- cat /data/message.txt
```

Output:

```text
Hello from PVC
```

---

## 10. Deleting Pod does not delete PVC/PV

```bash
kubectl delete pod pvc-demo-pod
kubectl get pvc
kubectl get pv
```

The PVC and PV still remain in `Bound` state.

This proves that the data survives the Pod lifecycle because it is stored in the persistent volume layer, not the container filesystem.

---

## 11. Important concept

A PVC is not the disk itself.

```text
PVC = request + binding
PV = actual storage resource
Storage = real data backend
```

So:

```text
PVC != disk
```

---

## 12. Developer vs Administrator

### Administrator

- creates PVs
- sets up storage classes
- manages backend storage

### Developer

- creates PVCs
- requests required storage
- does not worry about the underlying storage implementation

---

## 13. Static provisioning

In this lesson, the PV was created manually.

Flow:

```text
Admin creates PV
Developer creates PVC
Kubernetes binds PVC to PV
Pod mounts PVC
```

---

## 14. PVC protection

If a PVC is still in use by a Pod and deletion is attempted, Kubernetes may keep it in:

```text
Terminating
```

This prevents accidental data loss while the volume is still active.

---

## 15. Most important difference

```text
PV provides storage
PVC requests storage
Pod uses the PVC
```

---

## 16. One-line definition

A PersistentVolumeClaim is a request for persistent storage made by a user or application in Kubernetes.

---

## 17. Common commands

```bash
kubectl get pv
kubectl apply -f demo-pvc.yaml
kubectl get pvc
kubectl apply -f pvc-demo-pod.yaml
kubectl get pod pvc-demo-pod
kubectl exec pvc-demo-pod -- cat /data/message.txt
kubectl delete pod pvc-demo-pod
kubectl get pvc
kubectl get pv
```

---

## 18. Final takeaway

PVC is the bridge between application storage needs and actual cluster storage.

It gives Kubernetes a clean abstraction:

- app asks for storage
- Kubernetes finds matching PV
- Pod mounts the PVC
- data persists beyond the Pod lifecycle

---

## 📝 Additional notes

- **Growing a volume:** you can increase `resources.requests.storage` on a PVC if its StorageClass has `allowVolumeExpansion: true`. Shrinking isn't supported.
- **Same namespace only:** a Pod can only use a PVC in its own namespace.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- [Expanding persistent volume claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims)
- [Deploying WordPress and MySQL with persistent volumes](https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
