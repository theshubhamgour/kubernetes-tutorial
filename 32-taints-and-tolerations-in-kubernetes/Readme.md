# Kubernetes Taints and Tolerations

This guide explains how Kubernetes uses **taints** on nodes and **tolerations** on Pods to influence scheduling. The hands-on example creates a three-node Minikube cluster, reserves one node with a taint, and compares a Deployment without a toleration to a Pod with a matching toleration.

## 1. Taints and Tolerations

Think of a node as a restricted room and Pods as people trying to enter:

- A **taint** is a restriction placed on a node. It repels Pods that do not tolerate it.
- A **toleration** is configured on a Pod and allows it to be considered for a node with a matching taint.

A toleration does **not** make Kubernetes choose that node. The scheduler still considers available resources and other scheduling rules. To target a particular node, pair the toleration with a rule such as `nodeSelector`.

## 2. Taint Syntax and Effects

Add a taint to a node with:

```bash
kubectl taint nodes NODE_NAME key=value:effect
```

For example, `dedicated=demo:NoSchedule` has the key `dedicated`, the value `demo`, and the effect `NoSchedule`.

| Effect | What happens to Pods that do not tolerate the taint? |
|--------|-------------------------------------------------------|
| `NoSchedule` | New Pods will not be scheduled on the node. Existing Pods are not evicted just because this taint is added. |
| `PreferNoSchedule` | Kubernetes tries to avoid scheduling them there, but this is a preference rather than a guarantee. |
| `NoExecute` | New Pods will not be scheduled there, and existing non-tolerating Pods can be evicted. |

For a `NoExecute` taint, a matching toleration can use `tolerationSeconds` to limit how long a Pod remains after the taint is applied. Without a time limit, the Pod can tolerate the taint indefinitely.

## 3. Prerequisites

You will need:

- Minikube and `kubectl` installed and available on your `PATH`.
- A working Minikube driver and enough local resources to run three nodes.

Check that the tools are available:

```bash
minikube version
kubectl version --client
```

This tutorial creates a separate Minikube profile named `taints-demo`. The first start may take a few minutes while Minikube downloads the required images.

## 4. Create and Select a Three-Node Cluster

Start the cluster:

```bash
minikube start --nodes 3 -p taints-demo
```

Select the profile's Kubernetes context and verify the nodes:

```bash
kubectl config use-context taints-demo
kubectl config current-context
kubectl get nodes -o wide
```

The current context should be `taints-demo`, and the cluster should show three nodes in the `Ready` state. In the commands below, `taints-demo-m03` is the example third-node name. If your output shows a different name, substitute that node name wherever it appears.

## 5. What Is a Toleration?

A toleration is configured inside a Pod specification. It allows the Pod to tolerate a matching taint on a node.

For example, suppose a node has this taint:

```text
dedicated=demo:NoSchedule
```

This toleration matches that taint:

```yaml
tolerations:
  - key: dedicated
    operator: Equal
    value: demo
    effect: NoSchedule
```

The key (`dedicated`), value (`demo`), and effect (`NoSchedule`) match the taint. The `Equal` operator means the key and value must match.

A toleration does not guarantee that the Pod will run on that node; it only allows the Pod to be considered for scheduling there. To target a particular node, use a scheduling rule such as `nodeSelector` as well. The hands-on example below demonstrates both.

## 6. Taint the Third Node

Apply a `NoSchedule` taint to the example third node:

```bash
kubectl taint nodes taints-demo-m03 dedicated=demo:NoSchedule
```

Verify it:

```bash
kubectl describe node taints-demo-m03
```

Find the `Taints` field. It should include:

```text
dedicated=demo:NoSchedule
```

This taint prevents new Pods that do not tolerate it from being scheduled on this node. It does not automatically remove Pods that were already running there.

## 7. Schedule a Deployment Without a Toleration

The directory includes this Deployment manifest as [`nginx-deployment.yml`](./nginx-deployment.yml):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
```

The Pod template has no toleration for `dedicated=demo:NoSchedule`. Apply the Deployment and inspect where its Pods run:

```bash
kubectl apply -f nginx-deployment.yml
kubectl rollout status deployment/nginx-demo
kubectl get pods -o wide
```

Check the `NODE` column. The Deployment's Pods should be scheduled on eligible, untainted nodes rather than the tainted third node. Their exact distribution depends on the scheduler and available resources.

## 8. Allow a Pod to Run on the Tainted Node

The directory includes this Pod manifest as [`toleration-pod.yml`](./toleration-pod.yml). If the third node has a different name, update its `nodeSelector` value to match that node:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-toleration-pod
spec:
  nodeSelector:
    kubernetes.io/hostname: taints-demo-m03
  tolerations:
    - key: dedicated
      operator: Equal
      value: demo
      effect: NoSchedule
  containers:
    - name: nginx
      image: nginx:stable
      ports:
        - containerPort: 80
```

The `Equal` operator requires the taint's key and value to match; the effect also matches `NoSchedule`. The `nodeSelector` targets the third node, while the toleration allows the Pod to be scheduled there despite its taint.

Apply the Pod and verify its status and placement:

```bash
kubectl apply -f toleration-pod.yml
kubectl get pod nginx-toleration-pod -o wide
kubectl describe pod nginx-toleration-pod
```

When the Pod reaches `Running`, the `NODE` column should show the selected third node. If it does not, check the Pod's `Events`, confirm the node name and its `kubernetes.io/hostname` label, and make sure the node has enough available resources.

The comparison demonstrates both concepts:

- The Deployment without a matching toleration avoids the `NoSchedule` node.
- The Pod with a matching toleration is allowed onto that node, and its `nodeSelector` targets it.

## 9. Quick Revision and Cleanup

Remember:

- **Taints go on nodes** and repel Pods that do not tolerate them.
- **Tolerations go on Pods** and allow them to be considered for tainted nodes.
- **A toleration is not a placement rule.** Use a `nodeSelector` or another scheduling rule when a workload must target a particular node.
- `NoSchedule`, `PreferNoSchedule`, and `NoExecute` have different scheduling and eviction behavior.

Remove the demo resources and taint when finished. Replace the node name if yours differs:

```bash
kubectl delete deployment nginx-demo
kubectl delete pod nginx-toleration-pod
kubectl taint nodes taints-demo-m03 dedicated=demo:NoSchedule-
```

To remove the Minikube profile and its cluster:

```bash
minikube delete -p taints-demo
```