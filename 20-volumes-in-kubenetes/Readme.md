# Kubernetes Volumes

This tutorial introduces Kubernetes Volumes through a series of practical examples. It explains how Volumes are defined, mounted, and managed throughout the lifecycle of a Pod.

## 1. Scope

This tutorial focuses on Kubernetes Volumes and the following Volume configurations:

- `emptyDir`
- `hostPath`
- `emptyDir` with `medium: Memory`

Persistent-storage concepts are outside the scope of this tutorial. A subsequent lesson will cover:

- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)
- StorageClass

---

## 2. Problem Statement

A container has its own writable filesystem. Although an application can create files there, the data is tied to the container filesystem and should not be treated as durable storage.

For example:

```text
Container
   ↓
Creates data
   ↓
Container is replaced
   ↓
New container
   ↓
Old container filesystem data is not there
```

A Kubernetes Volume gives containers in a Pod access to a storage location. The lifecycle and behavior of that storage depend on the Volume type.

---

## 3. Kubernetes Volumes

A **Volume** is a storage location made available by Kubernetes to containers in a Pod. Containers can use the mounted location to read and write files.

From inside the container, a Volume normally appears as a directory such as:

```text
/data
```

The application can use that directory like a normal filesystem location, subject to the Volume type and permissions.

---

## 4. `volumes` and `volumeMounts`

These fields define complementary parts of the Volume configuration.

### `volumes`

The `volumes` field defines the Volume at the **Pod** level.

### `volumeMounts`

The `volumeMounts` field specifies where the Volume is mounted inside a **specific container**.

The relationship can be represented as follows:

```text
Pod
 |
 +── volumes
 |
 +── Container
       |
       +── volumeMounts
```

In summary:

```text
Volume
  ↓
"This storage exists."

Volume Mount
  ↓
"Expose this storage to this container at this path."
```

Example relationship:

```text
Volume name: shared-storage

        ↓

Mount path inside container: /shared
```

---

## 5. Experiment 1: Container Storage Without a Volume

Before using a Kubernetes Volume, create a Pod without a Volume.

### Create the manifest

Create a file named `no-volume.yaml`:

```yaml
apiVersion: v1                 
kind: Pod                      
metadata:                      
  name: no-volume-demo         
spec:                          
  containers:                  
    - name: app                
      image: busybox            
      command:                
        - sh                  
        - -c                    
        - sleep 3600           
```

### Create the Pod

```bash
kubectl apply -f no-volume.yaml
kubectl get pod no-volume-demo
```

The Pod should enter the `Running` phase.

### Create a file inside the container

```bash
kubectl exec no-volume-demo -- sh -c 'mkdir -p /data && echo "Hello Kubernetes" > /data/message.txt'
```

Read the file:

```bash
kubectl exec no-volume-demo -- cat /data/message.txt
```

Expected output:

```text
Hello Kubernetes
```

At this point, the file exists only in the container's writable filesystem. The Pod does not define a Kubernetes Volume.

### Recreate the Pod and check the file again

This procedure demonstrates that the container filesystem should not be used for data that must survive container replacement.

Delete the Pod:

```bash
kubectl delete pod no-volume-demo
```

Recreate it from the manifest:

```bash
kubectl apply -f no-volume.yaml
kubectl get pod no-volume-demo
```

Attempt to read the previous file:

```bash
kubectl exec no-volume-demo -- cat /data/message.txt
```

The file should no longer be present.

### Result

The file was written into the container filesystem, not a Kubernetes Volume.

```text
Container filesystem
        ↓
     Data file
        ↓
Container replaced
        ↓
   Data is gone
```

---

## 6. The `emptyDir` Volume Type

`emptyDir` is a Kubernetes Volume type that provides temporary storage for a Pod.

When a Pod is created, Kubernetes creates an initially empty directory for that Pod. Containers in the same Pod can share it.

Its lifecycle behavior is as follows:

```text
Container restarts
       ↓
Pod still exists
       ↓
emptyDir remains

Pod is deleted
       ↓
emptyDir is deleted
```

---

## 7. Sharing `emptyDir` Between Two Containers

Create a file named `emptydir-demo.yaml`:

```yaml
apiVersion: v1                                      
kind: Pod                                           
metadata:                                           
  name: emptydir-demo                               
spec:                                               
  containers:                                       
    - name: writer                                  
      image: busybox                                
      command:                                      
        - sh                                        
        - -c                                        
        - trap 'exit 1' TERM; while true; do sleep done                           
      volumeMounts:                                 
        - name: shared-storage                      
          mountPath: /shared                        
    - name: reader                                  
      image: busybox                                
      command:                                      
        - sh                                        
        - -c                                        
        - sleep 3600                                
      volumeMounts:                                 
        - name: shared-storage                      
          mountPath: /shared                        
  volumes:                                          
    - name: shared-storage                          
      emptyDir: {}                                  
```

### Apply the Pod

```bash
kubectl apply -f emptydir-demo.yaml
kubectl get pod emptydir-demo
```

Both containers should be running. The `READY` column should display a value such as:

```text
2/2
```

### Write from the writer container

```bash
kubectl exec emptydir-demo -c writer -- sh -c 'echo "Hello from writer" > /shared/message.txt'
```

Read it from the writer:

```bash
kubectl exec emptydir-demo -c writer -- cat /shared/message.txt
```

Expected output:

```text
Hello from writer
```

### Read the same file from the reader container

```bash
kubectl exec emptydir-demo -c reader -- cat /shared/message.txt
```

Expected output:

```text
Hello from writer
```

### Result

Both containers mounted the same `emptyDir` Volume at `/shared`.

```text
Writer Container
       |
       ↓
   emptyDir
       ↑
       |
Reader Container
```

Therefore, one container can write data and another container in the same Pod can read the same data.

---

## 8. Volume Name and Mount Path

The following values represent different concepts:

```text
shared-storage
```

and:

```text
/shared
```

`shared-storage` is the **Kubernetes Volume name**.

`/shared` is the **mount path inside the container**.

```text
Volume name
shared-storage
      ↓
Mounted inside container
/shared
```

---

## 9. `emptyDir` and Container Restarts

Yes. `emptyDir` follows the **Pod lifecycle**, not the lifecycle of an individual container.

### Create a test file

```bash
kubectl exec emptydir-demo -c writer -- sh -c 'echo "This should survive the container restart" > /shared/restart-test.txt'
```

Verify it from the reader:

```bash
kubectl exec emptydir-demo -c reader -- cat /shared/restart-test.txt
```

Expected output:

```text
This should survive the container restart
```

### Restart the writer container

```bash
kubectl exec emptydir-demo -c writer -- sh -c 'kill 1' || true
```

The command may report an error because the main process was intentionally killed.

Check the Pod:

```bash
kubectl get pod emptydir-demo
```

If necessary, wait for both containers to return to the `Running` state.

Now read the file from the reader container:

```bash
kubectl exec emptydir-demo -c reader -- cat /shared/restart-test.txt
```

The file should still be present:

```text
This should survive the container restart
```

### Lifecycle

```text
Container restarts
       ↓
Pod remains
       ↓
emptyDir remains
       ↓
File is still available
```

---

## 10. Pod Deletion and `emptyDir`

First confirm that the file still exists:

```bash
kubectl exec emptydir-demo -c reader -- cat /shared/restart-test.txt
```

Delete the Pod:

```bash
kubectl delete pod emptydir-demo
```

Recreate the Pod:

```bash
kubectl apply -f emptydir-demo.yaml
kubectl get pod emptydir-demo
```

Try to read the previous file:

```bash
kubectl exec emptydir-demo -c reader -- cat /shared/restart-test.txt
```

The file should not be present.

The original Pod was deleted, so its `emptyDir` was also deleted. The recreated Pod received a new, empty directory.

```text
Container restart
       ↓
Pod stays
       ↓
emptyDir stays

Pod deleted
       ↓
emptyDir deleted
```

### `emptyDir` Lifecycle Rule

> `emptyDir` survives container restarts but is deleted when the Pod is removed.

---

## 11. Appropriate Uses for `emptyDir`

Use `emptyDir` for **temporary working data**, including:

- Temporary files
- Cache data
- Shared workspace
- Intermediate files

A simple example:

```text
Container A
    ↓
Creates temporary file
    ↓
 emptyDir
    ↓
Container B
    ↓
Processes the file
```

The data is temporary. `emptyDir` is not intended to provide permanent application storage.

---

## 12. Standard `emptyDir` Storage

A normal `emptyDir` uses storage available on the Kubernetes node.

The exact underlying medium depends on the node environment. In a typical Linux environment, it uses local ephemeral storage.

Conceptually:

```text
Pod
 ↓
emptyDir
 ↓
Node storage
```

For this reason, `emptyDir` is considered temporary storage.

---

## 13. Memory-Backed `emptyDir` Volumes

`emptyDir` can also use memory instead of normal node storage.

The setting is:

```yaml
medium: Memory
```

On Linux, Kubernetes implements this using a RAM-backed filesystem called `tmpfs`.

Conceptually:

```text
emptyDir
   ↓
 tmpfs
   ↓
 RAM
```

---

## 14. Create a Memory-Backed `emptyDir` Volume

Create a file named `memory-emptydir-demo.yaml`:

```yaml
apiVersion: v1                                
kind: Pod                                     
metadata:                                     
  name: memory-emptydir-demo                  
spec:                                         
  containers:                                 
    - name: app                               
      image: busybox                          
      command:                                
        - sh                                  
        - -c                                  
        - sleep 3600                          
      volumeMounts:                           
        - name: memory-storage                
          mountPath: /cache                   
  volumes:                                    
    - name: memory-storage                    
      emptyDir:                               
        medium: Memory                        
```

Apply it:

```bash
kubectl apply -f memory-emptydir-demo.yaml
kubectl get pod memory-emptydir-demo
```

The Pod should enter the `Running` phase.

---

## 15. Verify `medium: Memory` with `tmpfs`

Verify the filesystem mounted inside the container rather than relying solely on the manifest.

Run:

```bash
kubectl exec memory-emptydir-demo -- df -hT /cache
```

Inspect the filesystem type. The output should include:

```text
tmpfs
```

This confirms that the mounted directory is backed by a memory filesystem.

```text
medium: Memory
      ↓
    tmpfs
      ↓
RAM-backed filesystem
```

### Create a file in the memory-backed Volume

```bash
kubectl exec memory-emptydir-demo -- sh -c 'echo "Stored in memory-backed emptyDir" > /cache/message.txt'
```

Read it:

```bash
kubectl exec memory-emptydir-demo -- cat /cache/message.txt
```

Expected output:

```text
Stored in memory-backed emptyDir
```

Verify the filesystem again if required:

```bash
kubectl exec memory-emptydir-demo -- df -hT /cache
```

The filesystem type should still be `tmpfs`.

---

## 16. Standard and Memory-Backed `emptyDir` Volumes

| Type | Simple meaning |
|---|---|
| `emptyDir` | Temporary storage for the Pod |
| `emptyDir` with `medium: Memory` | Temporary RAM-backed storage |

The main difference is the storage medium:

```text
Normal emptyDir
    ↓
Node storage

Memory emptyDir
    ↓
tmpfs
    ↓
RAM
```

The Volume type is still `emptyDir`; only the storage medium changes.

### Resource Consideration

Memory is a limited resource.

When using `medium: Memory`, files written to the Volume consume memory. Large amounts of data can create memory pressure for the Pod or node.

Use memory-backed `emptyDir` only for suitable temporary workloads and account for its memory consumption.

---

## 17. The `hostPath` Volume Type

The `hostPath` Volume type differs from `emptyDir`.

Instead of Kubernetes creating temporary storage for the Pod, `hostPath` mounts a file or directory from the **Kubernetes node's filesystem** into the Pod.

Conceptually:

```text
Kubernetes Node
      |
      └── /data/my-app
              |
           hostPath
              |
              ↓
          Container
              |
              └── /data
```

---

## 18. Minikube Consideration

When using Minikube with the Docker driver, `hostPath` refers to the filesystem of the **Kubernetes node environment**.

It does not automatically refer to a regular directory on the host macOS filesystem.

For this tutorial, use the following node path:

```text
/data/hostpath-demo
```

This path belongs to the Minikube node environment.

---

## 19. Create the `hostPath` Directory on the Minikube Node

Create the directory:

```bash
minikube ssh -- sudo mkdir -p /data/hostpath-demo
```

Confirm it exists:

```bash
minikube ssh -- ls -ld /data/hostpath-demo
```

---

## 20. Create a Pod with `hostPath`

Create a file named `hostpath-demo.yaml`:

```yaml
apiVersion: v1                                      
kind: Pod                                           
metadata:                                           
  name: hostpath-demo                               
spec:                                               
  containers:                                       
    - name: app                                     
      image: busybox                                
      command:                                      
        - sh                                        
        - -c                                        
        - sleep 3600                                
      volumeMounts:                                 
        - name: host-storage                        
          mountPath: /data                          
  volumes:                                          
    - name: host-storage                            
      hostPath:                                     
        path: /data/hostpath-demo                   
        type: Directory                             
```

### Apply the Pod

```bash
kubectl apply -f hostpath-demo.yaml
kubectl get pod hostpath-demo
```

The Pod should enter the `Running` phase.

---

## 21. Verify `hostPath`

Create a file from inside the container:

```bash
kubectl exec hostpath-demo -- sh -c 'echo "Hello from hostPath" > /data/message.txt'
```

Read it from the container:

```bash
kubectl exec hostpath-demo -- cat /data/message.txt
```

Expected output:

```text
Hello from hostPath
```

Now read the same file directly from the Minikube node:

```bash
minikube ssh -- sudo cat /data/hostpath-demo/message.txt
```

Expected output:

```text
Hello from hostPath
```

This confirms that the file is stored in the node directory mounted through `hostPath`.

---

## 22. Comparing `hostPath` and `emptyDir`

### `emptyDir`

Kubernetes creates temporary storage for the Pod.

```text
Pod
 ↓
emptyDir
 ↓
temporary node storage
```

### `hostPath`

The manifest explicitly identifies a location on the node.

```text
Pod
 ↓
hostPath
 ↓
specific node directory
```

### Fundamental Difference

| Volume type | Simple meaning |
|---|---|
| `emptyDir` | Kubernetes gives the Pod temporary storage |
| `hostPath` | You point the Pod to a specific node path |

---

## 23. Pod Deletion and `hostPath`

The file is currently stored in the Minikube node directory.

Delete the Pod:

```bash
kubectl delete pod hostpath-demo
```

The Pod is gone, but the node directory still exists.

Check the file:

```bash
minikube ssh -- sudo cat /data/hostpath-demo/message.txt
```

Expected output:

```text
Hello from hostPath
```

Deleting the Pod does not delete the node directory.

```text
Pod deleted
    ↓
Pod disappears
    ↓
Node directory remains
```

### Recreate the Pod

```bash
kubectl apply -f hostpath-demo.yaml
kubectl get pod hostpath-demo
```

Read the file again from inside the new Pod:

```bash
kubectl exec hostpath-demo -- cat /data/message.txt
```

Expected output:

```text
Hello from hostPath
```

The new Pod can see the old file because the file lives on the node.

---

## 24. Limitations of `hostPath`

`hostPath` is tied to a particular node.

For example:

```text
Node 1
/data/hostpath-demo
```

Assume that the application is running on Node 1.

If the Pod is later scheduled on:

```text
Node 2
```

Node 2 does not automatically contain the same directory or data from Node 1.

That means:

```text
hostPath
   ↓
specific node
```

Consequently, `hostPath` is node-specific and can reduce portability.

---

## 25. `hostPath` Security Considerations

`hostPath` gives a Pod access to part of the node's filesystem.

This can be useful for specific node-level use cases, but an incorrect path or permission configuration can expose files that the application should not access.

For this hands-on exercise, a dedicated demo directory is used:

```text
/data/hostpath-demo
```

---

## 26. The `hostPath.type` Field

The demo uses:

```yaml
type: Directory
```

This tells Kubernetes to expect the path to already exist as a directory.

We created it with:

```bash
minikube ssh -- sudo mkdir -p /data/hostpath-demo
```

Other `hostPath.type` values include:

```text
Directory
DirectoryOrCreate
File
FileOrCreate
```

The key considerations are:

```text
hostPath
   ↓
Which node path?
   ↓
What type of path is it?
```

---

## 27. Common Configuration Error: Volume Without a Mount

Defining a Volume does not automatically make it available inside a container.

You normally define:

```text
volumes
```

and then mount it into the container with:

```text
volumeMounts
```

Think:

```text
Volume
  +
Volume Mount
  ↓
Container can use the Volume at the mount path
```

If the mount is omitted, the container will not see the Volume at the expected path.

---

## 28. Lifecycle Comparison

### Container filesystem

```text
Container created
       ↓
Data exists
       ↓
Container replaced
       ↓
Data is gone
```

### `emptyDir`

```text
Pod created
       ↓
emptyDir created
       ↓
Container restarts
       ↓
Data remains
       ↓
Pod deleted
       ↓
Data is gone
```

### `hostPath`

```text
Node directory
       ↓
Pod mounts it
       ↓
Pod deleted
       ↓
Node directory remains
```

`hostPath` remains tied to the node where the referenced path exists.

---

## 29. Comparison Table

| Type | Meaning | Container restart | Pod deletion | Important point |
|---|---|---|---|---|
| Container filesystem | Data inside the container writable layer | Data should not be treated as durable | Gone with container replacement | Tied to the container filesystem |
| `emptyDir` | Temporary Pod storage | Survives | Deleted | Belongs to the Pod lifecycle |
| `emptyDir` + `medium: Memory` | Temporary RAM-backed storage | Survives | Deleted | Uses `tmpfs` / memory |
| `hostPath` | Specific directory from the node | Survives while mounted to that node path | Node data remains | Node-specific and security-sensitive |

---

## 30. When to Use `emptyDir`

Use `emptyDir` when you need temporary working storage:

```text
Temporary files
Cache
Shared workspace
Intermediate files
```

Example:

```text
Container A
    ↓
creates temporary file
    ↓
 emptyDir
    ↓
Container B
    ↓
processes file
```

Once the Pod is gone, the temporary data is gone too.

---

## 31. When to Use `hostPath`

Use `hostPath` when you specifically need access to a directory or file on the Kubernetes node.

It is useful for node-level use cases, but it is not the general solution for application data that must survive Pod movement between nodes.

Remember:

```text
hostPath
   ↓
node-specific
   ↓
not automatically shared across nodes
```

---

## 32. Considerations for Database Data

Imagine a database such as MySQL storing:

- Customers
- Orders
- Payments
- Transactions

Important database data should not normally be placed in `emptyDir`.

Deleting the Pod deletes the associated `emptyDir` data.

Using `hostPath` is generally not the appropriate solution either.

The data would be tied to a particular node and would not automatically follow the application if it moved to another node.

This is where Kubernetes persistent-storage concepts become important.

That is intentionally outside the scope of this lesson.

---

## 33. Scope Summary

### Covered here

```text
Volume
  ↓
volumes
  ↓
volumeMounts
  ↓
emptyDir
  ↓
emptyDir lifecycle
  ↓
Shared emptyDir
  ↓
Memory-backed emptyDir
  ↓
 tmpfs verification
  ↓
hostPath
  ↓
Node filesystem
  ↓
Lifecycle and limitations
```

### Next lesson

```text
PersistentVolume
        ↓
PersistentVolumeClaim
        ↓
StorageClass
```

Those topics will be covered in a dedicated lesson on persistent storage.

---

## 34. Hands-On Troubleshooting

When troubleshooting a Volume issue, begin by inspecting the Pod and then verify the mount configuration.

### Check Pods

```bash
kubectl get pod
```

### Describe the Pod

```bash
kubectl describe pod <pod-name>
```

Review the events and the Volume and mount information.

### Check where the Pod is running

```bash
kubectl get pod <pod-name> -o wide
```

This is particularly important when working with `hostPath`, because the node determines which data is available.

### Open a shell in the container

```bash
kubectl exec -it <pod-name> -c <container-name> -- sh
```

### Check the mounted directory

```bash
kubectl exec <pod-name> -c <container-name> -- ls -la /data
```

### Read a file from the mounted path

```bash
kubectl exec <pod-name> -c <container-name> -- cat /data/message.txt
```

### Inspect the Minikube node for `hostPath`

```bash
minikube ssh
ls -ld /data/hostpath-demo
```

### Common Checks

- The Volume name in `volumeMounts` matches the name under `volumes`.
- The `mountPath` is the path you are actually using inside the container.
- The `hostPath.path` exists on the Kubernetes node when using `type: Directory`.
- The Pod is running on the node where the expected `hostPath` data exists.

---

## 35. Cleanup

Remove the demo Pods:

```bash
kubectl delete -f no-volume.yaml
kubectl delete -f emptydir-demo.yaml
kubectl delete -f memory-emptydir-demo.yaml
kubectl delete -f hostpath-demo.yaml
```

Remove the `hostPath` demo directory from the Minikube node:

```bash
minikube ssh -- sudo rm -rf /data/hostpath-demo
```

---

## 36. Conclusion

The central concept of this tutorial is:

> **A Kubernetes Volume gives containers inside a Pod access to a filesystem location or data source, and the behavior depends on the type of Volume you choose.**

Remember these three examples:

```text
emptyDir
   → temporary Pod storage

emptyDir + medium: Memory
   → temporary RAM-backed storage

hostPath
   → a path from the Kubernetes node filesystem
```

The storage journey then continues with:

```text
PersistentVolume
        ↓
PersistentVolumeClaim
        ↓
StorageClass
```

That is where the dedicated persistent-storage lesson begins.

---

## 📝 Additional notes

- **Limit `emptyDir` size:** set `emptyDir.sizeLimit` so one Pod can't fill the node's disk. If it's exceeded, the Pod is evicted. Memory-backed volumes count towards the container's memory usage.
- **Mount read-only when you can:** `readOnly: true` on a `volumeMount` protects data from accidental writes.
- **Mounting one path:** `subPath` mounts a single file or folder from a volume. Files mounted this way don't receive ConfigMap or Secret updates.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Ephemeral volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/)
- [Configure a Pod to use a volume for storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
