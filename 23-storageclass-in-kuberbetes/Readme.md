# StorageClass in Kubernetes

## 1. Definition

A StorageClass is a Kubernetes resource that defines how storage should be created dynamically.

It is not actual storage itself. It is a template or policy that tells Kubernetes:

- which provisioner to use
- what kind of storage to create
- what reclaim policy to apply
- when the volume should be bound

In simple terms:

- PV = actual storage resource
- PVC = request for storage
- StorageClass = instructions for creating storage automatically

---

## 2. Why do we need StorageClass?

Earlier, we had to create a PV manually and then create a PVC to bind it.

In real clusters, this is not practical because there may be many applications with different storage needs.

Example:

- Application A needs 10Gi
- Application B needs 50Gi
- Application C needs 100Gi

Creating a PV manually every time is inefficient.

StorageClass solves this problem by enabling automatic provisioning.

---

## 3. Dynamic provisioning

Dynamic provisioning means:

Storage is created automatically when a PVC requests it.

The process is:

1. User creates a PVC
2. PVC specifies a StorageClass
3. Kubernetes checks the StorageClass
4. Storage provisioner creates the storage
5. Kubernetes creates a PV automatically
6. PVC binds to the PV

This eliminates manual PV creation.

---

## 4. StorageClass is not the storage

StorageClass does not contain application data.

It does not store files or data.

It is only a definition used to create storage.

The actual storage is represented by a dynamically created PV.

---

## 5. Real-world analogy

Think of ordering a cab.

You do not create the car yourself. You just request a ride and choose a category such as:

- Economy
- Premium

The service already knows which vehicles to use and how to provide them.

StorageClass works in the same way.

The user creates a PVC and says:

- I need 10Gi of storage
- I want this StorageClass

The StorageClass tells Kubernetes which provisioner to use and how the storage should be created.

---

## 6. StorageClass fields

Example:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: demo-storage
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

### apiVersion

```yaml
apiVersion: storage.k8s.io/v1
```

This indicates the API group and version used by StorageClass.

### kind

```yaml
kind: StorageClass
```

This tells Kubernetes that the object is a StorageClass.

### metadata.name

```yaml
metadata:
  name: demo-storage
```

This is the name of the StorageClass.

A PVC later refers to it using:

```yaml
storageClassName: demo-storage
```

### provisioner

```yaml
provisioner: k8s.io/minikube-hostpath
```

This is the most important field.

It tells Kubernetes which component is responsible for creating the storage.

This component is called the provisioner.

A provisioner knows how to create storage in a specific environment.

For example, cloud providers or local environments use different provisioners.

### reclaimPolicy

```yaml
reclaimPolicy: Delete
```

This decides what happens to the PV when the PVC is deleted.

Possible values:

- Delete: PV and storage are deleted
- Retain: PV is retained for manual cleanup

With Delete, dynamically created storage is cleaned up automatically.

### volumeBindingMode

```yaml
volumeBindingMode: Immediate
```

This defines when Kubernetes should provision and bind the volume.

Two common modes are:

- Immediate: provision as soon as PVC is created
- WaitForFirstConsumer: wait until a pod consumes the PVC

For this demo, Immediate is used.

---

## 7. StorageClass with Minikube

We create a fresh Minikube cluster.

```bash
minikube start --profile storage-class-demo --driver=docker
kubectl get nodes
kubectl config current-context
kubectl get storageclass
```

Minikube already provides a default StorageClass, but we create our own to understand the behavior clearly.

Create file: `storage-class.yaml`

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: demo-storage
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

Apply it:

```bash
kubectl apply -f storage-class.yaml
kubectl get storageclass
kubectl describe storageclass demo-storage
```

We should see the StorageClass details such as:

- Provisioner
- ReclaimPolicy
- VolumeBindingMode

---

## 8. Parameters section

A StorageClass may also include a `parameters` block.

Example:

```yaml
parameters:
  type: pd-ssd
```

These parameters are specific to the storage provisioner.

They may define things like:

- disk type
- performance tier
- replication settings

In this Minikube example, no parameters are required.

---

## 9. Create a PVC using the StorageClass

Now we create a PVC that requests storage from the StorageClass.

Create file: `dynamic-pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: demo-storage
  resources:
    requests:
      storage: 1Gi
```

Important line:

```yaml
storageClassName: demo-storage
```

This tells Kubernetes:

- I need 1Gi storage
- Use the `demo-storage` class
- Provision it dynamically

Apply:

```bash
kubectl apply -f dynamic-pvc.yaml
kubectl get pvc
```

The PVC should become Bound.

---

## 10. Observe dynamic provisioning

Even though we did not create a PV manually, Kubernetes creates one automatically.

```bash
kubectl get pvc
kubectl get pv
kubectl describe pv <generated-pv-name>
```

Check the PV details:

- StorageClass: demo-storage
- Claim: default/dynamic-pvc

This is the key idea behind dynamic provisioning.

---

## 11. PVC-PV relationship

```bash
kubectl get pv,pvc
```

Output shows:

- PVC is Bound
- PV is Bound
- StorageClass is demo-storage
- Reclaim policy is Delete

This confirms that Kubernetes automatically provisioned and bound the storage.

---

## 12. Use the PVC in a Pod

Create file: `dynamic-pod.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dynamic-storage-pod
spec:
  containers:
    - name: app
      image: busybox
      command:
        - sh
        - -c
        - sleep 3600
      volumeMounts:
        - name: app-storage
          mountPath: /data
  volumes:
    - name: app-storage
      persistentVolumeClaim:
        claimName: dynamic-pvc
```

Apply:

```bash
kubectl apply -f dynamic-pod.yaml
kubectl get pod dynamic-storage-pod
```

Check that the pod is Running.

---

## 13. Write and read data

```bash
kubectl exec dynamic-storage-pod -- sh -c 'echo "Hello from dynamically provisioned storage" > /data/message.txt'
kubectl exec dynamic-storage-pod -- cat /data/message.txt
```

Output:

```text
Hello from dynamically provisioned storage
```

This proves the pod is using the dynamically provisioned persistent volume.

---

## 14. Delete the pod but keep PVC

```bash
kubectl delete pod dynamic-storage-pod
kubectl get pvc
kubectl get pv
```

The PVC and PV still exist.

This shows that the storage belongs to the PVC/PV relationship, not to the pod itself.

---

## 15. Recreate Pod and check data persists

```bash
kubectl apply -f dynamic-pod.yaml
kubectl exec dynamic-storage-pod -- cat /data/message.txt
```

We should still see:

```text
Hello from dynamically provisioned storage
```

This proves persistence is maintained across pod recreation as long as the PVC remains.

---

## 16. Automatic cleanup with reclaimPolicy: Delete

Delete the pod:

```bash
kubectl delete pod dynamic-storage-pod
```

Delete the PVC:

```bash
kubectl delete pvc dynamic-pvc
```

Now check:

```bash
kubectl get pv
```

The dynamically provisioned PV should be removed automatically because of:

```yaml
reclaimPolicy: Delete
```

This is the benefit of dynamic provisioning with cleanup policy enabled.

---

## 17. One StorageClass can be used by many PVCs

A single StorageClass can be used by multiple PVCs.

Example:

- PVC A -> 10Gi
- PVC B -> 20Gi
- both use `storageClassName: demo-storage`

Each claim can trigger its own PV creation according to the same class.

So the StorageClass defines the common provisioning rules, while each PVC requests its own storage requirement.

---

## 18. Summary

StorageClass is used to automate storage provisioning in Kubernetes.

Key points:

- It defines how storage should be created
- It uses a provisioner to create storage
- It allows PVCs to request storage without manual PV creation
- It enables automatic dynamic provisioning
- It can automatically delete storage when the PVC is removed

This makes Kubernetes storage management scalable, automated, and easier to manage in production environments.

```yaml
storageClassName: demo-storage
```

This tells Kubernetes:

- I need 1 Gi of storage
- The access mode should be ReadWriteOnce
- Use the `demo-storage` StorageClass for provisioning

Apply the PVC:

```bash
kubectl apply -f dynamic-pvc.yaml
kubectl get pvc
```

The output should show the PVC in a `Bound` state and a dynamically generated PV behind it.

---

## 10. Observing Dynamic Provisioning

After creating the PVC, Kubernetes automatically creates a PV for it.

```bash
kubectl get pvc
kubectl get pv
kubectl describe pv <generated-pv-name>
```

The dynamically created PV will include details such as:

- `StorageClass: demo-storage`
- `Claim: default/dynamic-pvc`
- `Reclaim Policy: Delete`

This demonstrates that storage provisioning is now automated. The user did not create a PV manually; Kubernetes created it automatically based on the StorageClass.

---

## 11. Verifying the Relationship Between PVC and PV

The relationship can be checked with:

```bash
kubectl get pv,pvc
```

The output should look similar to:

```text
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS
persistentvolume/pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  1Gi        RWO            Delete           Bound    default/dynamic-pvc    demo-storage

NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
persistentvolumeclaim/dynamic-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   1Gi        RWO            demo-storage
```

This confirms the following:

- the PVC is bound
- the PV exists
- the PV was created dynamically
- the StorageClass is `demo-storage`
- reclaim policy is `Delete`

---

## 12. Using the Dynamically Provisioned Storage in a Pod

To test the storage, we attach the PVC to a Pod.

Create a file named `dynamic-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dynamic-storage-pod
spec:
  containers:
    - name: app
      image: busybox
      command:
        - sh
        - -c
        - sleep 3600
      volumeMounts:
        - name: app-storage
          mountPath: /data
  volumes:
    - name: app-storage
      persistentVolumeClaim:
        claimName: dynamic-pvc
```

Apply the Pod:

```bash
kubectl apply -f dynamic-pod.yaml
kubectl get pod dynamic-storage-pod
```

The Pod should become `Running`.

---

## 13. Writing and Reading Data

Once the Pod is running, we can write data to the mounted storage:

```bash
kubectl exec dynamic-storage-pod -- sh -c 'echo "Hello from dynamically provisioned storage" > /data/message.txt'
kubectl exec dynamic-storage-pod -- cat /data/message.txt
```

The output should be:

```text
Hello from dynamically provisioned storage
```

This confirms that the pod is successfully consuming the dynamically provisioned storage and that data persists on the mounted volume.

---

## 14. Data Persistence When the Pod Is Deleted

Now delete the Pod:

```bash
kubectl delete pod dynamic-storage-pod
```

Do not delete the PVC at this stage.

Check the resources again:

```bash
kubectl get pvc
kubectl get pv
```

The PVC and PV should still be present. The storage is not tied to the Pod itself; it is tied to the PVC and the dynamically created PV.

Recreate the Pod and confirm that the file remains available:

```bash
kubectl apply -f dynamic-pod.yaml
kubectl exec dynamic-storage-pod -- cat /data/message.txt
```

The content should still be available:

```text
Hello from dynamically provisioned storage
```

This demonstrates persistence across Pod recreation when the PVC remains in place.

---

## 15. Demonstrating Automatic Cleanup with reclaimPolicy: Delete

Now test the reclaim logic.

Delete the Pod first:

```bash
kubectl delete pod dynamic-storage-pod
```

Then delete the PVC:

```bash
kubectl delete pvc dynamic-pvc
```

Check the PV:

```bash
kubectl get pv
```

Because the StorageClass uses:

```yaml
reclaimPolicy: Delete
```

Kubernetes removes the dynamically created PV when the PVC is deleted.

This is an important operational feature of dynamic provisioning: storage does not remain indefinitely after the claim is removed unless a different reclaim policy is configured.

---

## 16. Single StorageClass Across Multiple PVCs

A single StorageClass can support multiple PVCs. For example, two different applications may each request storage from the same class:

- PVC A requests 10Gi
- PVC B requests 20Gi
- both use `storageClassName: demo-storage`

Even though both claims use the same StorageClass, each request can lead to a separate dynamically provisioned PV. This makes the StorageClass a reusable policy template rather than a single storage object.

---

## 17. Summary

A StorageClass is a Kubernetes resource that defines the rules for creating storage dynamically. It avoids the manual creation of PVs for each storage request and allows Kubernetes to provision storage automatically based on the PVC specification.

Key ideas:

- StorageClass defines how storage should be provisioned
- provisioner performs the actual storage creation
- PVC requests storage from a StorageClass
- Kubernetes automatically creates a matching PV
- reclaimPolicy determines what happens when the PVC is deleted
- storage can be reused by different pods through the same PVC

This is a core concept in Kubernetes storage management and an essential component of scalable, cloud-native application deployment.

---

## 18. Final Note

StorageClass is not just a storage object; it is a provisioning policy. It allows Kubernetes to handle storage requests in a declarative and automated manner, which is essential in dynamic and production-grade environments.

Understanding StorageClass is critical for managing persistent storage effectively in Kubernetes, especially when working with clusters that need to support a wide variety of workloads and storage backends.
