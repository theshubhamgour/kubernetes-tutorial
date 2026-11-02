# Kubernetes Networking Simplified 


This builds the mental model first. Detailed topics such as
Services, ClusterIP, NodePort, LoadBalancer, Ingress, NetworkPolicy, and
deeper networking behavior are covered in later videos.

The central question is:

``` text
Who is communicating with whom?
How do they find each other?
How does Kubernetes keep that communication working?
```

------------------------------------------------------------------------

# 1. What Are We Trying to Solve?

Kubernetes runs applications inside Pods.

But applications need to communicate.

We need answers to questions like:

-   How does one Pod talk to another Pod?
-   How does an application find another application?
-   What happens when a Pod disappears?
-   How do we expose an application outside the cluster?
-   How do we control which applications are allowed to communicate?

This is the purpose of Kubernetes networking.

Kubernetes networking helps us understand:

``` text
Pod communication
Stable access to changing Pods
Service discovery
External access
Traffic control
```

------------------------------------------------------------------------

# 2. Networking in One Simple Example

Imagine two applications:

``` text
Frontend  --->  Backend
```

The frontend needs a way to find and communicate with the backend.

In networking, we commonly use:

``` text
IP Address + Port
```

Example:

``` text
10.244.1.10:80
```

Think of it like:

``` text
IP Address = Building Address
Port       = Door / Application
```

So:

**IP tells us where.**

**Port tells us which application/service at that location.**

## Docker Connection

Docker containers can communicate through container networking. Kubernetes
extends this idea across many Pods and multiple machines in a cluster.

------------------------------------------------------------------------

# 3. Pods Have IP Addresses

A Kubernetes Pod participates in the cluster network and can have its
own IP.

Example:

``` text
nginx-pod
IP: 10.244.1.10
```

Another Pod:

``` text
client-pod
IP: 10.244.1.11
```

Conceptually:

``` text
+-------------------+       +-------------------+
|    nginx-pod      |       |    client-pod     |
|                   |       |                   |
| 10.244.1.10       | <---- | 10.244.1.11       |
|                   |       |                   |
| NGINX :80         |       | curl / client     |
+-------------------+       +-------------------+
```

Pods can communicate over the cluster network.

------------------------------------------------------------------------

# 4. Why Pod IPs Are Not Enough

Suppose we have:

``` text
backend-1    10.244.1.10
backend-2    10.244.1.11
backend-3    10.244.1.12
```

If the application depends directly on these IPs, we have a problem.

What happens if:

``` text
backend-2
    X
```

Kubernetes creates a replacement:

``` text
backend-4    10.244.1.25
```

The IP changed.

Remember:

> **Pods are disposable.**

Therefore:

> **Do not treat an individual Pod IP as a permanent application
> endpoint.**

------------------------------------------------------------------------

# 5. The Solution: Service

A Kubernetes Service provides a stable way to access a changing group of
Pods.

``` text
                 backend-service
                       |
          +------------+------------+
          |            |            |
          v            v            v
       backend-1    backend-2    backend-3
```

The client talks to:

``` text
backend-service
```

rather than tracking individual Pod IPs.

If a Pod disappears:

``` text
backend-2
    X
```

and Kubernetes creates:

``` text
backend-4
```

the Service can continue selecting the appropriate Pods.

------------------------------------------------------------------------

# 6. Labels + Selectors

Services use selectors to identify their backend Pods.

Pods:

``` yaml
labels:
  app: backend
```

Service:

``` yaml
selector:
  app: backend
```

Conceptually:

``` text
Service
selector:
  app: backend
       |
       +----> backend-1
       |
       +----> backend-2
       |
       +----> backend-3
```

This is why labels and selectors are extremely important in Kubernetes.

------------------------------------------------------------------------

# 7. Basic Deployment Example

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
          ports:
            - containerPort: 80
```

Important relationship:

``` text
Deployment selector
        |
        v
    app: nginx
        |
        v
Pod labels
    app: nginx
```

------------------------------------------------------------------------

# 8. What Does containerPort Mean?

Example:

``` yaml
ports:
  - containerPort: 80
```

This indicates the port associated with the container.

But remember:

> `containerPort` by itself does **not** expose the application outside
> the cluster.

To provide stable network access to Pods, we commonly use a Service.

------------------------------------------------------------------------

# 9. Basic Service

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

The most important part is:

``` yaml
selector:
  app: nginx
```

It connects the Service to Pods with:

``` yaml
labels:
  app: nginx
```

------------------------------------------------------------------------

# 10. port vs targetPort

Example:

``` yaml
ports:
  - port: 80
    targetPort: 8080
```

Think:

``` text
Client
   |
   | Service :80
   v
Service
   |
   | forwards to :8080
   v
Pod / Application
```

Remember:

``` text
port       = Service port
targetPort = backend Pod/application port
```

They can be the same:

``` yaml
port: 80
targetPort: 80
```

Or different:

``` yaml
port: 80
targetPort: 8080
```

------------------------------------------------------------------------

# 11. Three Important IP Concepts

You will hear three different IP concepts.

## Pod IP

IP assigned to a Pod.

Example:

``` text
10.244.1.10
```

Pod IPs can change when Pods are recreated.

## ClusterIP

Stable internal IP associated with a Service.

Example:

``` text
10.96.0.10
```

Used primarily for communication inside the cluster.

## Node IP

IP address of a Kubernetes node.

Example:

``` text
192.168.1.20
```

Visual:

``` text
Node IP
  |
  +---- Pod IP
  |
  +---- Pod IP
  |
  +---- Pod IP

Service
  |
  +---- ClusterIP
```

------------------------------------------------------------------------

# 12. Kubernetes DNS

Applications should not need to remember every Service IP.

Instead, Kubernetes provides DNS-based Service discovery.

Example:

``` text
backend-service
```

Instead of:

``` text
http://10.96.0.10
```

applications can conceptually use:

``` text
http://backend-service
```

A fully qualified Service DNS name can look like:

``` text
backend-service.default.svc.cluster.local
```

Mental model:

``` text
Service Name
     |
     v
   DNS
     |
     v
Service
```

Remember:

> **Service = stable access**

> **DNS = discover the Service by name**

# 13. Service Types --- High-Level View

There are several Service types.

## ClusterIP

``` text
Inside Cluster
      |
      v
ClusterIP Service
      |
      v
Pods
```

Think:

> Stable internal access.

------------------------------------------------------------------------

## NodePort

``` text
External Client
      |
      | NodeIP:NodePort
      v
 Kubernetes Node
      |
      v
   Service
      |
      v
     Pods
```

Think:

> Expose a Service through a port on Kubernetes nodes.

Example:

``` text
192.168.1.20:30080
```

------------------------------------------------------------------------

## LoadBalancer

``` text
Internet
   |
   v
External Load Balancer
   |
   v
Service
   |
   v
Pods
```

Think:

> Expose a Service through external load-balancing infrastructure where
> supported.

------------------------------------------------------------------------

# 14. Quick Comparison

  Type           Main Idea
  -------------- -----------------------------------------------------
  ClusterIP      Internal Service access
  NodePort       Service exposed through a node port
  LoadBalancer   External load-balancing integration where supported

Detailed behavior will be covered in later videos.

------------------------------------------------------------------------

# 15. Ingress

Ingress is mainly about:

> **HTTP/HTTPS routing to Services.**

Example:

``` text
                  Internet
                     |
                     v
                  Ingress
                 /       \
                /         \
               v           v
      frontend-service   backend-service
              |               |
              v               v
        frontend Pods     backend Pods
```

Example routing:

``` text
/       ---> frontend-service
/api    ---> backend-service
```

Important:

> An Ingress resource generally requires an Ingress controller to
> actually implement the routing behavior.

------------------------------------------------------------------------

# 16. Service vs Ingress

Do not treat these as the same thing.

``` text
Service
   |
   +---- Stable access to Pods

Ingress
   |
   +---- HTTP/HTTPS routing to Services
```

A common architecture:

``` text
Internet
   |
   v
Ingress
   |
   +---- frontend-service ---> frontend Pods
   |
   +---- backend-service  ---> backend Pods
```

------------------------------------------------------------------------

# 17. NetworkPolicy

Networking is not only about allowing communication.

We also need to control communication.

Imagine:

``` text
Frontend
Backend
Database
```

We may want:

``` text
Frontend ---> Backend
Backend  ---> Database
```

But:

``` text
Frontend -X-> Database
```

NetworkPolicy can define rules for allowed or restricted traffic.

Conceptually:

``` text
Frontend
    |
    | ALLOW
    v
Backend
    |
    | ALLOW
    v
Database

Frontend
    |
    | DENY
    X
Database
```

Important:

> NetworkPolicy enforcement depends on the networking implementation
> used by the cluster.

------------------------------------------------------------------------

# 18. Service vs NetworkPolicy

These solve different problems.

``` text
Service
   |
   +---- How do I reach the application?

NetworkPolicy
   |
   +---- Who is allowed to communicate?
```

Think:

**Service = connectivity/discovery**

**NetworkPolicy = traffic control**

------------------------------------------------------------------------

# 19. Complete Networking Picture

``` text
                         USERS
                           |
                           v
                        INGRESS
                           |
                           v
                       SERVICE
                           |
                +----------+----------+
                |          |          |
                v          v          v
              POD        POD        POD
            Pod IP      Pod IP      Pod IP
                |
                |
        NetworkPolicy
        controls traffic
```

For internal applications:

``` text
Frontend Pod
     |
     | backend-service
     v
Backend Service
     |
     v
Backend Pods
```

------------------------------------------------------------------------

# 20. Real-World Application Example

Imagine an application with:

``` text
Frontend
Backend
Database
```

Each component runs in Kubernetes.

We might have:

``` text
frontend-service
backend-service
database-service
```

Architecture:

``` text
Frontend Pods
      |
      | backend-service
      v
Backend Service
      |
      v
Backend Pods
      |
      | database-service
      v
Database Service
      |
      v
Database Pods
```

The applications communicate using stable Service names rather than
individual Pod IPs.

------------------------------------------------------------------------

# 21. The Full Request Flow

A possible external request:

``` text
User
 |
 | HTTPS
 v
Ingress
 |
 | HTTP routing
 v
Backend Service
 |
 | selects Pods
 v
Backend Pod
 |
 | allowed by network rules
 v
Application
```

The exact architecture depends on the application and environment, but
this is the mental model to carry forward.

------------------------------------------------------------------------

# 22. Troubleshooting Flow

When networking doesn't work, don't randomly change YAML.

Use a sequence.

## Step 1 --- Is the Pod running?

``` bash
kubectl get pods
```

## Step 2 --- What is the Pod IP?

``` bash
kubectl get pods -o wide
```

## Step 3 --- Does the Service exist?

``` bash
kubectl get svc
```

## Step 4 --- Do labels match selectors?

``` bash
kubectl get pods --show-labels
```

## Step 5 --- Does the Service have endpoints?

``` bash
kubectl get endpoints
```

or:

``` bash
kubectl get endpointslices
```

## Step 6 --- Does DNS work?

From a suitable client Pod:

``` bash
nslookup backend-service
```

## Step 7 --- Can we connect?

``` bash
curl http://backend-service
```

## Step 8 --- Check traffic restrictions

``` bash
kubectl get networkpolicy
```

Then inspect a policy:

``` bash
kubectl describe networkpolicy <policy-name>
```

Also consider firewalls, cloud networking rules, and the cluster's
networking implementation.

------------------------------------------------------------------------

# 23. Common Mistakes

## Mistake 1 --- Hard-coding Pod IPs

Bad mental model:

``` text
Application ---> Pod IP
```

Better:

``` text
Application ---> Service ---> Pods
```

------------------------------------------------------------------------

## Mistake 2 --- Assuming containerPort exposes the application

``` yaml
containerPort: 80
```

does not itself create an external Service.

------------------------------------------------------------------------

## Mistake 3 --- Selector mismatch

Service:

``` yaml
selector:
  app: backend
```

Pod:

``` yaml
labels:
  app: frontend
```

These do not match.

The Service may have no backend endpoints.

------------------------------------------------------------------------

## Mistake 4 --- Confusing port and targetPort

Remember:

``` text
port       = Service port
targetPort = Pod/application port
```

------------------------------------------------------------------------

## Mistake 5 --- Treating Ingress as a replacement for Service

``` text
Ingress ---> Service ---> Pods
```

Ingress normally routes to Services.

------------------------------------------------------------------------

## Mistake 6 --- Assuming NetworkPolicy is automatically enforced

NetworkPolicy only has an effect when the cluster networking
implementation supports and enforces it.

------------------------------------------------------------------------

# 24. The Most Important Mental Model

Remember this:

``` text
Pod
 ↓
Pod IP
 ↓
Pods can communicate

Service
 ↓
Stable access to Pods

Labels + Selectors
 ↓
Identify which Pods belong to a Service

DNS
 ↓
Find Services by name

Ingress
 ↓
HTTP/HTTPS routing

NetworkPolicy
 ↓
Control allowed traffic
```

------------------------------------------------------------------------

# 25. Final Summary

``` text
                INTERNET / USERS
                       |
                       v
                    INGRESS
                 HTTP / HTTPS
                       |
                       v
                    SERVICE
                 Stable endpoint
                       |
            +----------+----------+
            |          |          |
            v          v          v
           POD        POD        POD
         Pod IP      Pod IP      Pod IP
            |
            |
      NetworkPolicy
      Traffic control
```

### Remember

1.  Pods have IP addresses.
2.  Pod IPs can change.
3.  Services provide stable access.
4.  Services use labels and selectors.
5.  DNS lets applications find Services by name.
6.  ClusterIP is mainly internal Service access.
7.  NodePort exposes a Service through a node port.
8.  LoadBalancer can integrate with external load balancing.
9.  Ingress provides HTTP/HTTPS routing to Services.
10. NetworkPolicy controls allowed network traffic.

------------------------------------------------------------------------

# 26. What Comes Next?

This video is only the networking foundation.

Upcoming videos can go deeper into:

``` text
Services
   ↓
ClusterIP
   ↓
NodePort
   ↓
LoadBalancer
   ↓
DNS
   ↓
Endpoints / EndpointSlices
   ↓
Ingress
   ↓
NetworkPolicy
   ↓
Deeper Kubernetes networking
```

The goal is not to memorize terminology.

The goal is to understand:

``` text
WHO
 |
 v
is communicating?

HOW
 |
 v
do they find each other?

WHERE
 |
 v
does the request go?

WHO
 |
 v
is allowed to communicate?
```

Once this mental model is clear, the detailed Kubernetes networking
concepts become much easier to learn.

---

## 📝 Additional notes

- **The core rule:** every Pod gets its own cluster-wide IP, and Pods can reach each other across nodes without NAT. The CNI plugin provides this.
- **How a Service IP works:** on each node, `kube-proxy` (or a CNI replacement for it) programs rules that forward Service traffic to the backend Pods.
- **Quick local test:** `kubectl port-forward svc/<service> 8080:80` reaches a Service from your machine without exposing it. It's for debugging, not production.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Cluster networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Services, load balancing and networking](https://kubernetes.io/docs/concepts/services-networking/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
