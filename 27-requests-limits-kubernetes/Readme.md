# Kubernetes Resource Requests and Limits

This lesson explains how Kubernetes manages CPU and memory for containers using resource requests and limits.

## 1. Scope

This lesson covers:

- the difference between requests and limits
- CPU and memory quantity units
- how requests affect scheduling
- what happens when a container reaches its CPU or memory limit
- Kubernetes Quality of Service (QoS) classes
- common operational considerations

---

## 2. Why Resources Matter

Containers running on a Kubernetes node share finite CPU and memory. Kubernetes needs information about the resources a workload expects and the maximum resources it may use.

Resource requests and limits communicate that information to Kubernetes. They help the scheduler place Pods and help the node control resource consumption.

---

## 3. Requests and Limits

Resource settings are specified for containers.

- **Request**: the amount of a resource Kubernetes uses when scheduling the Pod. It represents the amount the container is expected to need.
- **Limit**: the maximum amount of a resource the container is allowed to consume.

A request is not a hard usage cap. When a node has available resources, a container can use more than its request, up to its limit if one is configured.

Requests and limits are separate settings. A container may have a request without a limit, a limit without an explicitly specified request, both, or neither. Admission configuration such as a `LimitRange` can apply default values, so the effective settings may differ from what was written in a Pod manifest.

---

## 4. CPU Quantities

Kubernetes CPU quantities represent cores or virtual cores. CPU can be specified as a whole or fractional amount.

- `1` CPU represents one core or virtual core
- `1000m` is equivalent to `1` CPU
- `500m` is equivalent to half a CPU
- `250m` is equivalent to one quarter of a CPU

The suffix `m` means millicpu. CPU resources are compressible: when a container reaches its CPU limit, it is throttled rather than normally terminated.

---

## 5. Memory Quantities

Memory quantities commonly use binary suffixes such as `Ki`, `Mi`, and `Gi`, representing kibibytes, mebibytes, and gibibytes. Kubernetes also supports decimal quantity suffixes such as `K`, `M`, and `G`; binary and decimal units are not identical.

Memory is a non-compressible resource. When a container exceeds its memory limit and the node cannot satisfy its memory allocation, the kernel may terminate a process in the container. Kubernetes commonly reports this as an `OOMKilled` container state.

---

## 6. How Requests Affect Scheduling

The Kubernetes Scheduler considers the resource requests of a Pod when choosing a node. It compares those requests with the node's available allocatable capacity and the requests of workloads already scheduled there.

If no suitable node has enough available requested capacity, the Pod remains `Pending` until capacity becomes available or the scheduling constraints change.

The request is used for scheduling and resource accounting; it does not reserve an exclusive portion of the node for the container. Actual usage can be higher or lower than the request.

---

## 7. How Limits Are Enforced

CPU and memory limits behave differently.

### CPU limit

CPU is compressible. When a container tries to use more CPU time than its configured limit allows, the runtime throttles it. The container usually continues running, but it may respond more slowly or complete work later.

### Memory limit

Memory is not compressible in the same way. If a container's memory use exceeds its limit and memory cannot be reclaimed or allocated, the kernel may kill a process in that container. The container can then be restarted according to its restart policy, and its last termination state may show `OOMKilled`.

An OOM kill is not a user-facing guarantee that termination occurs at one perfectly exact measurement. Runtime and node memory pressure can affect the observed behavior.

---

## 8. Kubernetes QoS Classes

Kubernetes assigns each Pod a Quality of Service (QoS) class based on the CPU and memory requests and limits of its containers.

### Guaranteed

A Pod is `Guaranteed` when every container has both CPU and memory requests and limits, and each request equals its corresponding limit.

### Burstable

A Pod is `Burstable` when it does not meet the `Guaranteed` criteria and at least one container has a CPU or memory request or limit.

### BestEffort

A Pod is `BestEffort` when none of its containers has a CPU or memory request or limit.

QoS class is one factor Kubernetes uses when responding to node resource pressure. It is not a general performance guarantee, and a QoS class by itself does not ensure that a workload will never be throttled, restarted, or evicted.

Cluster admission defaults can populate requests or limits even when they are not present in the original manifest. Inspect the admitted Pod when you need to understand its effective QoS class.

---

## 9. Inspect Resource Settings and QoS

Use Kubernetes inspection commands to review the resources recorded for a Pod and its assigned QoS class:

```bash
kubectl describe pod <pod-name>
kubectl get pod <pod-name> -o yaml
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}{"\n"}'
```

If a Pod is pending, inspect its events to find scheduling details:

```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by=.lastTimestamp
```

If a container was terminated, inspect the Pod's container status and last termination state for reasons such as `OOMKilled`.

---

## 10. Common Considerations

- Set requests based on observed workload behavior and capacity planning, rather than treating them as arbitrary values.
- A request that is too high can prevent a Pod from scheduling even when actual usage would have been lower.
- A request that is too low can lead to poor scheduling decisions and contention on a busy node.
- A CPU limit that is too low can throttle an application and increase latency.
- A memory limit that is too low can cause the container to be OOM-killed.
- Omitting a limit does not mean the application has dedicated or unlimited node capacity; workloads still share node resources.
- Monitor actual resource usage and revisit requests and limits as workload behavior changes.
- Consider all containers in a Pod when reasoning about scheduling and QoS, including sidecars and init containers.

---

## 11. Quick Summary

- Requests describe expected resource needs and are used by the scheduler.
- Limits define the maximum resource usage allowed for a container.
- Containers can use more than their request when resources are available, subject to configured limits.
- CPU limits are enforced through throttling.
- Exceeding a memory limit can result in an OOM kill.
- Kubernetes assigns Pods the `Guaranteed`, `Burstable`, or `BestEffort` QoS class based on container resource settings.
- Requests and limits affect scheduling and resource management, but do not guarantee application performance.

Resource requests and limits help Kubernetes make informed placement decisions and keep workloads from consuming resources without bounds. They work best when chosen from measured application behavior and reviewed as that behavior changes.
