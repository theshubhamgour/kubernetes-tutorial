# Kubernetes Terminologies

This document explains the core Kubernetes concepts used throughout the tutorial. It is intended as a reference for understanding Kubernetes workloads, networking, configuration, and security.

## Core Concepts

### Kubernetes Cluster
A Kubernetes cluster is the complete system that runs containerized applications. It includes:
- One or more control-plane components that manage the cluster state.
- One or more worker nodes that run your application workloads.

The cluster coordinates scheduling, scaling, and health checks for containers.

### Node
A node is a physical or virtual machine in the cluster. Each node runs a container runtime (such as Docker or containerd) and the Kubernetes node agent (`kubelet`). There are two types of nodes:
- Control plane node: runs the API server, scheduler, controller manager, and etcd.
- Worker node: runs application workloads inside pods.

### Pod
A pod is the smallest deployable unit in Kubernetes. It can contain one or more containers that share the same network namespace and storage volumes. Pods are usually created and managed by higher-level objects such as Deployments.

### Namespace
A namespace provides logical isolation within a single Kubernetes cluster. Namespaces allow you to separate resources by environment, team, or project while still sharing the same cluster.
- Example uses: `default`, `kube-system`, `development`, `production`.

## Workload Resources

### Deployment
A Deployment defines the desired state for an application. It manages replica sets, handles rolling updates, and ensures the correct number of application pod replicas are running.
- Use Deployments for stateless applications.
- Deployments support versioned rollouts and rollbacks.

### ReplicaSet
A ReplicaSet ensures that a specified number of identical pod replicas are running at all times. It monitors pods and creates or deletes them to match the desired replica count.
- Deployments use ReplicaSets under the hood.
- You usually manage pods through Deployments rather than directly via ReplicaSets.

### StatefulSet
A StatefulSet is used for stateful applications that require stable network identities and persistent storage. It ensures that pods are created in order and keeps each pod’s identity across restarts.
- Ideal for databases and clustered stateful services.
- Provides stable hostnames and stable storage volumes.

### DaemonSet
A DaemonSet ensures that a copy of a pod runs on every node, or on a subset of nodes. It is commonly used for cluster services such as logging agents, monitoring agents, or network proxies.

## Networking and Access

### Service
A Service is an abstraction that defines a logical set of pods and a policy for accessing them. Services provide stable network identities for pods and help route traffic to the correct endpoints.
- Common service types: `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`.

### ClusterIP
`ClusterIP` is the default Service type. It exposes the service on a stable internal IP address within the cluster. This is used for pod-to-pod communication.

### NodePort
A `NodePort` Service exposes an application on a static port on every node in the cluster. External traffic can reach the service by requesting any node’s IP address on that port.
- Useful for simple access from outside the cluster when a load balancer isn’t available.

### Load Balancer
A `LoadBalancer` Service provisions an external load balancer through the cloud provider. It exposes the service to external traffic and distributes requests across the backend pod endpoints.

### Ingress
Ingress provides rules for routing external HTTP and HTTPS traffic to Services inside the cluster. It typically uses an Ingress Controller to implement load balancing, SSL termination, and path-based routing.

## Configuration and Secrets

### ConfigMap
A ConfigMap stores non-sensitive configuration data as key-value pairs. Pods can consume ConfigMaps as environment variables, command-line arguments, or mounted volumes.
- Use ConfigMaps for settings such as application configuration files or runtime options.

### Secret
A Secret stores sensitive information such as passwords, API keys, and certificates. Secrets are stored separately from pods and can be mounted as files or injected as environment variables.
- Use Secrets to keep credentials out of container images and source control.

## Security and Metadata

### RBAC (Role-Based Access Control)
RBAC controls access to the Kubernetes API by defining roles and bindings.
- `Role` and `ClusterRole` define permissions.
- `RoleBinding` and `ClusterRoleBinding` attach those permissions to users, groups, or service accounts.

### Annotation
Annotations are key-value pairs attached to Kubernetes objects for storing metadata. They are not used for identifying objects, but for storing extra information that tooling and controllers can use.
- Example: build metadata, deployment notes, or operator-specific settings.

## Additional Concepts

### Load Balancer
In Kubernetes, a Load Balancer Service type creates an external-facing load balancer and forwards traffic to the Service’s pod endpoints.
- It is often used for public-facing applications in cloud environments.

### Cluster IP
A `ClusterIP` is the internal IP address assigned to a Service. It provides a stable way for other pods and services inside the cluster to reach that Service.

## Summary
This file defines the building blocks of Kubernetes operations: cluster components, workloads, networking, configuration, and security. Understanding these terms will make it easier to follow installation guides, manage resources with `kubectl`, and design Kubernetes-native applications.
---
---

---

## 📝 Additional notes

- **Explore from your terminal:** `kubectl api-resources` lists every resource type in your cluster, and `kubectl explain <resource>` describes its fields.
- **Look up a term:** the official glossary below has short definitions, and you can filter it to core Kubernetes terms.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Kubernetes glossary](https://kubernetes.io/docs/reference/glossary/)
- [Cluster architecture](https://kubernetes.io/docs/concepts/architecture/)
- [Kubernetes components](https://kubernetes.io/docs/concepts/overview/components/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
