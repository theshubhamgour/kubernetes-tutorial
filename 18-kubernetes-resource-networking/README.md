# Kubernetes Pod Networking Explained

## Pod-to-Pod, Container-to-Container, Cross-Node Communication, CNI, Services & DNS

This hands-on guide explains how networking works in Kubernetes, starting from communication between containers inside the same Pod and gradually moving to Pod-to-Pod communication, cross-node communication, CNI, Services, and Kubernetes DNS.

The goal is not to memorize networking terminology, but to understand what actually happens when Kubernetes workloads communicate.

---

# 1. What We Will Learn

We will cover Kubernetes networking in the following sequence:

1. Container-to-container communication inside the same Pod
2. Pod-to-Pod communication
3. Why Pod IPs are not permanent
4. Using Deployments to manage Pods
5. Pod-to-Pod communication on the same node
6. Pod-to-Pod communication across different nodes
7. What is CNI?
8. How CNI implements the Kubernetes Pod network
9. Pod-to-Pod communication without a Service
10. Pod-to-Service communication
11. Kubernetes DNS
12. End-to-end networking experiment

---

# 2. The Four Networking Problems in Kubernetes

Kubernetes networking can be understood as four separate problems:

### 1. Container-to-container communication

Communication between containers inside the same Pod.

### 2. Pod-to-Pod communication

Communication between separate Pods.

### 3. Pod-to-Service communication

Communication from a Pod to a Kubernetes Service.

### 4. External-to-Service communication

Communication from outside the cluster to a Service.

In this lesson, we focus heavily on the first two and then connect them to Services and DNS.

---

# 3. What Is a Pod Network?

Every Pod gets its own IP address.

All containers inside the same Pod share the Pod's network namespace.

Therefore, containers inside a Pod share:

- The same network interface
- The same Pod IP
- The same port space

Because they share the same network namespace, containers inside the same Pod can communicate using `localhost`.

Conceptually:

```text
Pod
│
├── Container A
│
└── Container B
```

Both containers use the same Pod network.

This is different from two containers running in separate Pods.

---

# 4. Hands-On: Two Containers Inside One Pod

We will create a Pod containing:

- An NGINX container
- A curl client container

The curl container will communicate with NGINX using `localhost`.

## 4.1 Create the YAML file

```bash
touch two-containers.yaml
```

Add the following:

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: two-containers

spec:
  containers:
    - name: web
      image: nginx

    - name: client
      image: curlimages/curl
      command:
        - sleep
        - "3600"
```

## 4.2 Apply the Pod

```bash
kubectl apply -f two-containers.yaml
```

## 4.3 Check the Pod

```bash
kubectl get pod two-containers
```

You should see:

```text
READY
2/2
```

`2/2` means both containers are running.

---

# 5. See the Containers Separately

Inspect the Pod:

```bash
kubectl describe pod two-containers
```

Look for the containers section.

You should see:

```text
web
client
```

So our Pod contains:

```text
two-containers
│
├── web
│
└── client
```

---

# 6. Enter the Client Container

Run:

```bash
kubectl exec -it two-containers -c client -- sh
```

Now we are inside the client container.

Test localhost:

```bash
curl http://localhost
```

You should receive the NGINX welcome page.

The important point is that we did **not** use:

- The Pod IP
- A Service
- An Ingress

We simply used:

```text
localhost
```

because both containers belong to the same Pod.

Exit the container:

```bash
exit
```

---

# 7. Verify NGINX

We can verify that the web container is running NGINX:

```bash
kubectl exec two-containers -c web -- nginx -v
```

This should display the NGINX version.

---

# 8. Why Does `localhost` Work?

Containers inside the same Pod share the same network namespace.

Therefore:

```text
Pod
│
├── web container
│      │
│      └── port 80
│
└── client container
       │
       └── localhost:80
```

The client container can reach NGINX through:

```text
localhost:80
```

because both containers share the same network namespace.

---

# 9. Important: Port Sharing Inside a Pod

Containers inside a Pod share the same port space.

Therefore, two containers in the same Pod cannot normally listen on the same IP and same port.

For example:

```text
Container A → port 80
Container B → port 80
```

would create a port conflict.

This is important when designing multi-container Pods.

Sidecar containers typically use different ports from the main application.

### Remember

> Same Pod = Shared Network

---

# 10. Pod-to-Pod Communication

Now we move one level higher.

Instead of:

```text
Container A → Container B
```

we want:

```text
Pod A → Pod B
```

These are two separate Pods.

We will create:

- A backend Pod running NGINX
- A client Pod running curl

---

# 11. Create the Backend Pod

Create the file:

```bash
touch backend-pod.yaml
```

Add:

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: backend-pod
  labels:
    app: backend

spec:
  containers:
    - name: backend
      image: nginx
```

Apply it:

```bash
kubectl apply -f backend-pod.yaml
```

Check the Pod and its IP:

```bash
kubectl get pod -o wide
```

Example:

```text
NAME          IP
backend-pod   10.244.x.x
```

The actual IP will be different in your cluster.

---

# 12. Create the Client Pod

Create:

```bash
touch client-pod.yaml
```

Add:

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: client-pod

spec:
  containers:
    - name: client
      image: curlimages/curl
      command:
        - sleep
        - "3600"
```

Apply:

```bash
kubectl apply -f client-pod.yaml
```

Check both Pods:

```bash
kubectl get pods -o wide
```

You should see something similar to:

```text
NAME          IP
backend-pod   10.244.0.10
client-pod    10.244.0.11
```

The actual IP addresses will depend on your cluster.

---

# 13. Find the Backend Pod IP

Run:

```bash
kubectl get pod backend-pod -o wide
```

Look at the `IP` column.

For example:

```text
10.244.0.10
```

---

# 14. Communicate Directly Using the Pod IP

Enter the client Pod:

```bash
kubectl exec -it client-pod -- sh
```

Now run:

```bash
curl http://10.244.0.10
```

Replace `10.244.0.10` with the actual backend Pod IP.

You should receive the NGINX response.

This proves that:

```text
Pod A
  │
  │ Pod IP
  ▼
Pod B
```

Pods can communicate directly using Pod IPs.

No Service is required for this basic Pod-to-Pod communication.

Exit:

```bash
exit
```

---

# 15. Why Don't We Normally Use Pod IPs?

If Pods can communicate directly using Pod IPs, why do we need Services?

Because Pod IPs are dynamic.

For example:

```text
backend Pod
    │
    └── 10.244.0.10
```

If that Pod is deleted and replaced, the replacement may receive:

```text
10.244.0.15
```

The old IP may no longer exist.

Therefore, applications should not normally hard-code Pod IP addresses.

This is where Kubernetes Services become important.

---

# 16. Prove That Pod IPs Can Change

Check the current IP:

```bash
kubectl get pod backend-pod -o wide
```

Take note of the IP.

Now delete the Pod:

```bash
kubectl delete pod backend-pod
```

Because we created the Pod directly, Kubernetes will not automatically recreate it.

Recreate it:

```bash
kubectl apply -f backend-pod.yaml
```

Check the IP:

```bash
kubectl get pod backend-pod -o wide
```

The Pod can receive a different IP.

This demonstrates why Pod IPs should not be treated as permanent application endpoints.

---

# 17. Use a Deployment Instead

In a real application, Pods are normally managed by higher-level Kubernetes controllers such as Deployments.

Delete the manually created Pod:

```bash
kubectl delete pod backend-pod
```

Create:

```bash
touch backend-deployment.yaml
```

Add:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: backend

spec:
  replicas: 2

  selector:
    matchLabels:
      app: backend

  template:
    metadata:
      labels:
        app: backend

    spec:
      containers:
        - name: backend
          image: nginx
```

Apply:

```bash
kubectl apply -f backend-deployment.yaml
```

Check:

```bash
kubectl get pods -o wide
```

We should now have two backend Pods.

For example:

```text
backend-xxxxx   IP A
backend-yyyyy   IP B
```

If one Pod is replaced, its IP can change.

This is one of the reasons we use Services.

---

# 18. Pod-to-Pod Communication on the Same Node

In a normal single-node Minikube cluster, the Pods will naturally run on the same node.

Check:

```bash
kubectl get pods -o wide
```

Look at the `NODE` column.

For example:

```text
NAME             NODE
backend-xxxxx    minikube
client-pod       minikube
```

Conceptually:

```text
Node
│
├── Client Pod
│
└── Backend Pod
```

We have already proven that these Pods can communicate using their Pod IPs.

---

# 19. Pod-to-Pod Communication Across Different Nodes

Now we move to the more interesting scenario.

What happens when:

```text
Node 1
│
└── Pod A
     10.244.1.x


Node 2
│
└── Pod B
     10.244.2.x
```

Can Pod A communicate directly with Pod B?

Yes.

The Kubernetes network model is designed so that Pods can communicate regardless of which node they are running on, assuming the cluster network is functioning and no intentional network segmentation blocks the traffic.

Let's prove it.

---

# 20. Create a Two-Node Minikube Cluster

Instead of destroying the existing Minikube environment, create a separate Minikube profile for this networking experiment.

Run:

```bash
minikube start --nodes 2 --driver=docker -p networking-demo
```

This creates a separate two-node Minikube cluster.

Switch to the new context:

```bash
kubectl config use-context networking-demo
```

Verify:

```bash
kubectl get nodes
```

You should see two nodes.

Example:

```text
NAME                  STATUS   ROLES
networking-demo       Ready    control-plane
networking-demo-m02   Ready    <none>
```

The actual names may differ.

Get additional information:

```bash
kubectl get nodes -o wide
```

---

# 21. Check the Pod Network

List all Pods:

```bash
kubectl get pods -A -o wide
```

Notice that Kubernetes system Pods also have Pod IP addresses.

The Pod network is part of the overall cluster network.

---

# 22. Create a Pod on Each Node

For this experiment, use a DaemonSet.

A DaemonSet ensures that one matching Pod runs on each eligible node.

Create:

```bash
touch network-test.yaml
```

Add:

```yaml
apiVersion: apps/v1
kind: DaemonSet

metadata:
  name: network-test

spec:
  selector:
    matchLabels:
      app: network-test

  template:
    metadata:
      labels:
        app: network-test

    spec:
      containers:
        - name: web
          image: nginx
```

Apply:

```bash
kubectl apply -f network-test.yaml
```

Now check:

```bash
kubectl get pods -o wide -l app=network-test
```

---

# 23. Observe the Two Nodes

You should see two Pods.

Example:

```text
NAME                NODE      IP
network-test-abc    node-1    10.244.0.10
network-test-def    node-2    10.244.1.10
```

The actual names and IPs will differ.

The important part is:

```text
Pod 1 → Node 1
Pod 2 → Node 2
```

Now we can test communication across nodes.

---

# 24. Create a Curl Client

Create a temporary client Pod:

```bash
kubectl run curl \
  --image=curlimages/curl \
  --restart=Never \
  --command -- \
  sleep 3600
```

Check:

```bash
kubectl get pod curl -o wide
```

Make sure the client Pod is running.

Now list the network-test Pods:

```bash
kubectl get pods -l app=network-test -o wide
```

Take the IP address of the Pod running on the other node.

For example:

```text
10.244.1.10
```

---

# 25. Test Cross-Node Pod Communication

Enter the curl Pod:

```bash
kubectl exec -it curl -- sh
```

Run:

```bash
curl http://10.244.1.10
```

Replace the IP with the actual Pod IP on the other node.

If the cluster networking is working, you should receive the NGINX response.

This proves:

```text
Node 1
│
└── Client Pod
       │
       │ Pod IP
       ▼
Node 2
│
└── NGINX Pod
```

A Pod can communicate with another Pod on a different node using its Pod IP.

---

# 26. What Is Actually Happening?

The client sends traffic to the destination Pod IP.

If the destination Pod is on another node, the traffic needs to leave the local node and reach the node hosting the destination Pod.

Conceptually:

```text
Node 1
│
└── Client Pod
       │
       │
       ▼
   Cluster Network
       │
       │
       ▼
Node 2
│
└── Backend Pod
```

The cluster networking implementation is responsible for making Pod-to-Pod communication work across nodes.

---

# 27. What Is CNI?

CNI stands for:

**Container Network Interface**

A CNI plugin helps implement the Kubernetes Pod network.

In simple terms, the networking implementation needs to:

- Create the Pod network interface
- Assign Pod IP addresses
- Connect Pods to the network
- Provide connectivity between Pods
- Potentially provide additional networking capabilities depending on the plugin

Kubernetes defines the networking model, while the actual network implementation is provided by the cluster's networking plugin.

Examples of CNI implementations include:

- Calico
- Cilium
- Flannel
- kindnet

The important idea is:

> Kubernetes expects a Pod network, and a CNI plugin helps implement that network.

---

# 28. CNI Is Not Kubernetes Networking Itself

It is common to hear:

> "Kubernetes networking is Calico."

That's not quite correct.

Think about it this way:

```text
Kubernetes
    │
    │ defines the networking model
    ▼
Networking Plugin / CNI
    │
    │ implements the networking
    ▼
Actual Pod Network
```

Kubernetes defines the expected networking behavior.

The CNI/networking implementation determines how that behavior is provided by the cluster.

Therefore, different Kubernetes clusters can use different networking plugins while still following the Kubernetes networking model.

---

# 29. Pod-to-Pod Does Not Need a Service

We have already demonstrated:

```text
Pod A → Pod B
```

using the Pod IP.

There was:

- No Service
- No Ingress

This is the underlying Pod network.

However, direct Pod IP communication is usually not what applications want because Pods are dynamic.

This gives us two different concepts:

```text
Pod-to-Pod Networking
```

and:

```text
Stable Application Access
```

Services solve the second problem.

---

# 30. Pod-to-Service Communication

Suppose we have backend Pods.

We create:

```text
backend-service
```

The client can now communicate with:

```text
backend-service
```

instead of tracking individual Pod IP addresses.

Conceptually:

```text
Client Pod
    │
    │ backend-service
    ▼
 Service
    │
    ├── Pod A
    │
    └── Pod B
```

The Service provides the stable abstraction.

---

# 31. Create a Backend Service

Create:

```bash
touch backend-service.yaml
```

Add:

```yaml
apiVersion: v1
kind: Service

metadata:
  name: backend-service

spec:
  selector:
    app: network-test

  ports:
    - port: 80
      targetPort: 80
```

Apply:

```bash
kubectl apply -f backend-service.yaml
```

Check:

```bash
kubectl get svc backend-service
```

The Service selects Pods with:

```text
app=network-test
```

Traffic arriving at Service port `80` is sent to port `80` on the selected backend Pods.

---

# 32. See the Service Endpoints

Run:

```bash
kubectl get endpoints backend-service
```

Also run:

```bash
kubectl get endpointslices
```

EndpointSlice objects contain backend endpoint information for Services.

They provide the connection between:

```text
Service
```

and:

```text
Current backend Pods
```

---

# 33. Test the Service From the Client Pod

Enter the client:

```bash
kubectl exec -it curl -- sh
```

Now run:

```bash
curl http://backend-service
```

You should receive the NGINX response.

Compare this with the earlier test:

```bash
curl http://<pod-ip>
```

Now we use:

```bash
curl http://backend-service
```

The Service provides a stable way to reach the backend Pods.

---

# 34. Kubernetes DNS

Kubernetes also provides DNS-based Service discovery.

Instead of thinking about the Service IP, applications can use the Service name:

```text
backend-service
```

instead of:

```text
10.x.x.x
```

For example:

```bash
curl http://backend-service
```

Kubernetes provides DNS records for Services and Pods.

Pods are configured so that they can look up Services by name.

For application configuration, this is normally much more useful than hard-coding IP addresses.

---

# 35. Final End-to-End Experiment

Now let's put everything together.

We will use the two-node cluster.

## Step 1 — Verify the Nodes

```bash
kubectl get nodes
```

We should have two nodes.

---

## Step 2 — Verify the Backend Pods

```bash
kubectl get pods -l app=network-test -o wide
```

We should have one backend Pod per node.

---

## Step 3 — Check the Service

```bash
kubectl get svc backend-service
```

---

## Step 4 — Check the Endpoints

```bash
kubectl get endpoints backend-service
```

---

## Step 5 — Enter the Client

```bash
kubectl exec -it curl -- sh
```

---

## Step 6 — Test the Pod Directly

Run:

```bash
curl http://<pod-ip>
```

Replace `<pod-ip>` with the actual backend Pod IP.

This request depends on one specific Pod.

---

## Step 7 — Test the Service

Run:

```bash
curl http://backend-service
```

This request uses the Service instead of a specific Pod IP.

---

# 36. Test What Happens When a Pod Is Deleted

Exit the client if necessary:

```bash
exit
```

List the backend Pods:

```bash
kubectl get pods -l app=network-test -o wide
```

Delete one backend Pod:

```bash
kubectl delete pod <pod-name>
```

Replace `<pod-name>` with the actual Pod name.

Wait for the DaemonSet to recreate the Pod.

Check:

```bash
kubectl get pods -l app=network-test -o wide
```

Now check the Service endpoints:

```bash
kubectl get endpoints backend-service
```

The backend endpoint information should reflect the current Pods.

---

# 37. Test the Service Again

Enter the client:

```bash
kubectl exec -it curl -- sh
```

Run:

```bash
curl http://backend-service
```

The Service should still work.

This demonstrates why we use:

```text
Pod Networking
       +
Service Abstraction
       +
DNS
```

instead of hard-coding Pod IP addresses.

---

# 38. Complete Kubernetes Networking Flow

The entire progression is:

```text
Container-to-Container
        │
        ▼
Pod-to-Pod
        │
        ▼
Cross-Node Pod-to-Pod
        │
        ▼
CNI
        │
        ▼
Service
        │
        ▼
DNS
```

Each layer solves a different problem.

---

# 39. Quick Reference

| Concept | What it provides |
|---|---|
| Container in same Pod | Shared network namespace |
| `localhost` | Communication between containers in the same Pod |
| Pod IP | Direct Pod-to-Pod communication |
| CNI | Implementation of the Pod network |
| Deployment | Manages and replaces Pods |
| Service | Stable access to changing Pods |
| EndpointSlice | Tracks Service backend endpoints |
| DNS | Allows applications to find Services by name |

---

# 40. Important Commands

### Same-Pod communication

```bash
kubectl exec -it two-containers -c client -- sh
```

```bash
curl http://localhost
```

### Pod IP

```bash
kubectl get pods -o wide
```

### Pod-to-Pod communication

```bash
kubectl exec -it client-pod -- sh
```

```bash
curl http://<pod-ip>
```

### Multi-node cluster

```bash
minikube start --nodes 2 --driver=docker -p networking-demo
```

```bash
kubectl config use-context networking-demo
```

```bash
kubectl get nodes
```

### Cross-node testing

```bash
kubectl get pods -l app=network-test -o wide
```

```bash
kubectl exec -it curl -- sh
```

```bash
curl http://<pod-ip>
```

### Service

```bash
kubectl get svc backend-service
```

```bash
kubectl get endpoints backend-service
```

```bash
kubectl get endpointslices
```

### Service DNS

```bash
curl http://backend-service
```

---

# 41. Key Takeaway

The most important thing to remember is:

> **Containers in the same Pod communicate through their shared network namespace, Pods communicate through the cluster Pod network, Services provide stable access to changing Pods, and DNS lets applications find those Services by name.**

Once these concepts are clear, Kubernetes networking becomes much less mysterious.

---

## 📝 Additional notes

- **Pod DNS settings:** look at `/etc/resolv.conf` inside a Pod. The `search` domains are why a short name like `backend` resolves, and `dnsPolicy` on the Pod controls this file.
- **Debugging DNS:** if names don't resolve, check that the CoreDNS Pods are healthy with `kubectl get pods -n kube-system -l k8s-app=kube-dns`.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Cluster networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Network plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Debugging DNS resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
