# Kubernetes Node Affinity & Node Anti-Affinity

This guide explains how Kubernetes uses node labels and scheduling rules to place Pods on specific nodes. It also covers node avoidance with the `NotIn` operator and the broader idea of anti-affinity in Kubernetes scheduling.

## 1. Introduction

Imagine a Kubernetes cluster with multiple nodes:

- one node has high CPU capacity
- another has more memory
- a third has SSD storage
- a fourth has HDD storage

If an application specifically requires SSD storage, you do not want Kubernetes to schedule it randomly. You want Kubernetes to place it only on a node that matches that requirement.

This is where Node Affinity becomes useful.

Node Affinity gives you a way to tell Kubernetes which nodes are suitable for a Pod based on node labels and matching rules. It is more flexible than `nodeSelector` and allows advanced logic such as:

- only run on nodes with `disk-type=ssd`
- prefer SSD nodes but allow fallback if needed
- avoid nodes with a particular label value

## 2. What Is Node Affinity?

Node Affinity is a scheduling rule that helps Kubernetes determine whether a node is suitable for a Pod.

For example, if a node is labeled:

```bash
kubectl label nodes NODE_NAME disk-type=ssd
```

then a Pod can be configured to require that label before it is scheduled:

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: disk-type
                operator: In
                values:
                  - ssd
```

This tells Kubernetes: "Schedule this Pod only on a node where `disk-type` has the value `ssd`." If no matching node exists, the Pod stays pending.

## 3. Two Types of Node Affinity

Kubernetes provides two main scheduling modes for Node Affinity.

### 3.1 `requiredDuringSchedulingIgnoredDuringExecution`

This is a strict requirement. Kubernetes must satisfy the rule when the Pod is originally scheduled.

Example:

```yaml
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: disk-type
          operator: In
          values:
            - ssd
```

If a matching node is not available, the Pod remains pending.

The `IgnoredDuringExecution` part means that if the node label changes later, Kubernetes will not automatically evict or reschedule the already-running Pod.

### 3.2 `preferredDuringSchedulingIgnoredDuringExecution`

This is a soft preference rather than a hard requirement.

Example:

```yaml
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    preference:
      matchExpressions:
        - key: disk-type
          operator: In
          values:
            - ssd
```

Kubernetes tries to satisfy the preference, but it can still schedule the Pod elsewhere if no preferred node is available.

The `weight` can range from 1 to 100. A higher weight makes that preference stronger.

## 4. Node Avoidance and Anti-Affinity

Affinity tells Kubernetes which nodes to prefer or require. Anti-affinity (or avoidance) tells Kubernetes which nodes to avoid.

A common approach is to use the `NotIn` operator:

```yaml
- key: disk-type
  operator: NotIn
  values:
    - ssd
```

This tells Kubernetes to avoid nodes where the label `disk-type=ssd` is present.

You can also think of it as an anti-affinity control for placement decisions.

It is useful when you want to:

- keep workloads off storage-specific nodes
- spread workloads across the cluster
- prevent placement onto known undesired nodes

There is also a more general concept of Pod Anti-Affinity, where Kubernetes tries to avoid placing matching Pods on the same node. This improves resilience and helps spread replicas across different nodes.

## 5. Prerequisites

You will need:

- Minikube installed
- `kubectl` installed and configured
- enough local resources to create a three-node cluster

Check the tools:

```bash
minikube version
kubectl version --client
```

## 6. Hands-On Demo: Create a Three-Node Cluster

Start a Minikube cluster with three nodes:

```bash
minikube start --nodes 3 -p affinity-demo
```

Select the cluster context:

```bash
kubectl config use-context affinity-demo
```

Verify the nodes:

```bash
kubectl get nodes
```

Now label nodes so we can demonstrate placement rules.

Example names may differ, so use the names from your own cluster output.

```bash
kubectl label nodes affinity-demo disk-type=ssd
kubectl label nodes affinity-demo-m02 disk-type=hdd
```

Check the labels:

```bash
kubectl get nodes --show-labels
kubectl get nodes -L disk-type
```

The first node should have `disk-type=ssd`, the second should have `disk-type=hdd`, and the third node will remain unlabeled.

## 7. Demo 1: Require an SSD Node

The [`pod.yml`](./pod.yml) manifest defines a Pod that requires `disk-type=ssd`.

Apply the Pod:

```bash
kubectl apply -f pod.yml
```

Check placement:

```bash
kubectl get pods -o wide
kubectl describe pod affinity-pod
```

The Pod should be scheduled on the node labeled `disk-type=ssd`.

## 8. Demo 2: Avoid SSD Nodes

The [`node-avoid.yml`](./node-avoid.yml) manifest uses `NotIn` to avoid SSD-labeled nodes.

Apply it:

```bash
kubectl apply -f node-avoid.yml
```

Check the placement:

```bash
kubectl get pods -o wide
kubectl describe pod avoid-affinity-pod
```

This Pod should be scheduled on a node that does not have `disk-type=ssd`.

> Note: `NotIn` can also match nodes where the label is absent. In more precise scenarios, you may combine it with another rule to ensure the label exists and has a different value.

## 9. Verify Results

Run:

```bash
kubectl get pods -o wide
kubectl get nodes -L disk-type
```

The output should show:

- `affinity-pod` running on the SSD node
- `avoid-affinity-pod` running on a non-SSD node

This confirms that the scheduling rules are being interpreted correctly by the Kubernetes scheduler.

## 10. Cleanup

Delete the Pods:

```bash
kubectl delete -f pod.yml
kubectl delete -f node-avoid.yml
```

Remove the labels:

```bash
kubectl label node YOUR_SSD_NODE_NAME disk-type-
kubectl label node YOUR_HDD_NODE_NAME disk-type-
```

The `-` at the end removes the label.

If you no longer need the Minikube cluster:

```bash
minikube delete -p affinity-demo
```

## 11. Key Takeaways

- Node Affinity lets you control where Pods can run based on labels.
- `requiredDuringSchedulingIgnoredDuringExecution` is mandatory during scheduling.
- `preferredDuringSchedulingIgnoredDuringExecution` is a soft preference.
- `NotIn` helps you avoid certain node labels.
- These rules are especially useful when workloads require a specific type of infrastructure, such as SSD-backed nodes.

## 12. Conclusion

Node Affinity is a powerful scheduling concept for Kubernetes clusters with heterogeneous node capabilities. It lets you define strong placement constraints, express preferences, and avoid specific node classes when needed. Combined with labels and node selection rules, it gives you more control over how workloads are placed in production environments.

This hands-on example demonstrates the core idea clearly: label the nodes, define matching rules, and let Kubernetes schedule workloads based on those conditions.
