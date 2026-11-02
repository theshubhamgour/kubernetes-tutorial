# Kubernetes Services Explained

## 1. The Problem: Pod IPs Are Not Reliable

Pods are temporary.

A Pod can be:

-   deleted
-   recreated
-   rescheduled to another node
-   replaced during an update
-   scaled up or down

Because of this, Pod IP addresses can change.

So applications should not depend directly on individual Pod IPs.

The key question is:

> **If Pod IPs keep changing, how does an application reliably
> communicate with a group of Pods?**

------------------------------------------------------------------------

## 2. What is Kubernetes Service ?

A **Service** provides a stable way to access a group of Pods.

Think of it like a receptionist or front desk.

``` text
Client
  |
  | "I need the backend application"
  v
Service
  |
  | Finds matching Pods
  v
+---------+---------+---------+
| Pod     | Pod     | Pod     |
| backend | backend | backend |
+---------+---------+---------+
```

The client does not need to know the IP address of every Pod.

The Service provides a stable access point while the underlying Pods can
change.

------------------------------------------------------------------------

## 3. A Service Is Not a Pod

A common beginner mistake is thinking that a Service runs the
application.

It does not.

``` text
Deployment
    |
    v
  Pods
    |
    | run the application
    v
Application

Service
    |
    | provides stable access
    v
Pods
```

### Responsibilities

**Deployment**

-   manages Pods
-   maintains the desired number of replicas
-   replaces failed Pods

**Pod**

-   runs the application container

**Service**

-   provides stable network access to matching Pods
-   keeps track of the current backend Pods
-   provides service discovery

------------------------------------------------------------------------

# 4. Example: NGINX Deployment

We will use NGINX as a simple example.

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

This creates three NGINX Pods.

``` text
             Deployment
                 |
        ---------------------
        |         |         |
       Pod       Pod       Pod
       nginx     nginx     nginx
```

Each Pod gets its own IP.

For example:

``` text
Pod 1 → 10.0.0.10
Pod 2 → 10.0.0.11
Pod 3 → 10.0.0.12
```

These IPs should not be treated as permanent addresses.

------------------------------------------------------------------------

# 5. Labels and Selectors

Services use **labels and selectors** to identify which Pods they should
send traffic to.

The Pods have this label:

``` yaml
labels:
  app: nginx
```

The Service uses:

``` yaml
selector:
  app: nginx
```

This means:

> Find Pods that have `app=nginx`.

``` text
Service
selector:
  app: nginx
       |
       v
+----------------------------+
| Find Pods with app=nginx   |
+----------------------------+
       |
       v
 Pod 1     Pod 2     Pod 3
 app=nginx app=nginx app=nginx
```

The selector is one of the most important parts of a Service.

------------------------------------------------------------------------

# 6. Create the First Service

Example:

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

This Service selects Pods with:

``` text
app=nginx
```

and forwards traffic to port `80` on those Pods.

------------------------------------------------------------------------

# 7. Understanding the Service YAML

### `apiVersion`

``` yaml
apiVersion: v1
```

Services are part of the Kubernetes core API.

------------------------------------------------------------------------

### `kind`

``` yaml
kind: Service
```

This tells Kubernetes that we are creating a Service.

------------------------------------------------------------------------

### `metadata.name`

``` yaml
metadata:
  name: nginx-service
```

This is the name of the Service.

Other applications inside the cluster can use this name for service
discovery.

------------------------------------------------------------------------

### `selector`

``` yaml
selector:
  app: nginx
```

This tells the Service which Pods are its backends.

The Service does not select Pods based on their names or IP addresses.

It selects them using labels.

------------------------------------------------------------------------

### `ports`

``` yaml
ports:
  - port: 80
    targetPort: 80
```

There are two important ports here.

**`port`**

The port exposed by the Service.

**`targetPort`**

The port on the backend Pod where traffic should be sent.

``` text
Client
  |
  | port 80
  v
Service
  |
  | targetPort 80
  v
NGINX Pod
```

------------------------------------------------------------------------

# 8. Create the Deployment

Save the Deployment as `deployment.yaml`.

``` bash
kubectl apply -f deployment.yaml
```

Check the Pods:

``` bash
kubectl get pods -o wide
```

You should see multiple NGINX Pods.

------------------------------------------------------------------------

# 9. Create the Service

Save the Service as `service.yaml`.

``` bash
kubectl apply -f service.yaml
```

Check the Service:

``` bash
kubectl get svc
```

You should see something similar to:

``` text
NAME            TYPE        CLUSTER-IP
nginx-service   ClusterIP   10.x.x.x
```

------------------------------------------------------------------------

# 10. ClusterIP: High-Level Understanding

The default Service type is:

``` yaml
type: ClusterIP
```

If `type` is not specified, Kubernetes creates a ClusterIP Service.

A ClusterIP provides an internal stable IP address for the Service.

``` text
Inside Cluster

Client Pod
    |
    v
Service
ClusterIP
    |
    v
NGINX Pods
```

It is normally used for communication between applications inside the
Kubernetes cluster.

------------------------------------------------------------------------

# 11. The Service Does Not Run NGINX

This distinction is important.

The NGINX application is running inside the Pods.

The Service provides a stable way to reach those Pods.

``` text
                 Service
             nginx-service
                    |
          ---------------------
          |         |         |
        Pod       Pod       Pod
       nginx     nginx     nginx
```

If all Pods disappear, the Service itself does not create new Pods.

That is the Deployment's responsibility.

------------------------------------------------------------------------

# 12. `port` vs `targetPort`

Consider:

``` yaml
ports:
  - port: 8080
    targetPort: 80
```

Traffic flow:

``` text
Client
  |
  | :8080
  v
Service
  |
  | forwards to :80
  v
Pod
```

Therefore:

``` text
port       = Service port
targetPort = Pod/application port
```

They do not have to be the same.

------------------------------------------------------------------------

# 13. `containerPort` vs `targetPort`

A Pod might contain:

``` yaml
containers:
  - name: nginx
    image: nginx
    ports:
      - containerPort: 80
```

And the Service might contain:

``` yaml
ports:
  - port: 8080
    targetPort: 80
```

Here:

``` text
containerPort = 80
Service port  = 8080
targetPort    = 80
```

### Important

`containerPort` does **not** by itself expose the application outside
the Pod.

It is primarily metadata describing the port the container expects to
use.

The Service is what provides a stable networking endpoint for the
application.

------------------------------------------------------------------------

# 14. Endpoints and EndpointSlices

How does Kubernetes know which Pods currently belong to the Service?

The Service selector identifies matching Pods, and Kubernetes maintains
backend endpoint information.

Check the endpoints:

``` bash
kubectl get endpoints nginx-service
```

You can also inspect EndpointSlices:

``` bash
kubectl get endpointslices
```

Conceptually:

``` text
Service
selector: app=nginx
        |
        v
Matching Pods
        |
        v
Endpoint information
        |
        v
Current backend addresses
```

This is important because Pods can continuously change.

------------------------------------------------------------------------

# 15. What Happens When a Pod Is Deleted?

Suppose we have:

``` text
Service
   |
   +---- Pod A
   +---- Pod B
   +---- Pod C
```

Delete Pod A:

``` bash
kubectl delete pod <pod-name>
```

The Deployment notices that one replica is missing.

It creates a replacement Pod.

``` text
Before:

Service
   |
   +---- Pod A
   +---- Pod B
   +---- Pod C

After deletion:

Service
   |
   +---- Pod B
   +---- Pod C
   +---- New Pod
```

The new Pod may receive a completely different IP.

The Service continues providing the stable access point.

------------------------------------------------------------------------

# 16. Scaling

Scale the Deployment:

``` bash
kubectl scale deployment nginx --replicas=5
```

Now the Service can route to the matching Pods.

``` text
Service
   |
   +---- Pod 1
   +---- Pod 2
   +---- Pod 3
   +---- Pod 4
   +---- Pod 5
```

Scale it back:

``` bash
kubectl scale deployment nginx --replicas=2
```

The Service automatically reflects the current matching backend Pods.

------------------------------------------------------------------------

# 17. The Important Idea: Dynamic Pods

Pods are dynamic.

``` text
Pod A → created
Pod A → deleted
Pod B → created
Pod C → created
Pod C → deleted
```

The Service provides a stable abstraction over this changing set of
Pods.

``` text
             Stable
               |
               v
           Service
               |
       -----------------
       |       |       |
      Pod     Pod     Pod
       ↑       ↑       ↑
     Dynamic backend Pods
```

------------------------------------------------------------------------

# 18. Service Discovery with DNS

Kubernetes provides DNS-based service discovery.

Instead of remembering the ClusterIP:

``` text
10.x.x.x
```

an application can communicate using:

``` text
nginx-service
```

For example:

``` bash
curl http://nginx-service
```

This is much easier than hardcoding an IP address.

------------------------------------------------------------------------

# 19. Namespaces and Service Names

If the Service is in the same namespace:

``` text
nginx-service
```

can usually be enough.

A more complete DNS name is:

``` text
nginx-service.default.svc.cluster.local
```

The structure is:

``` text
SERVICE
NAMESPACE
svc
cluster.local
```

Example:

``` text
nginx-service.default.svc.cluster.local
```

------------------------------------------------------------------------

# 20. The Most Common Service Bug: Selector Mismatch

Consider the Pod:

``` yaml
labels:
  app: nginx
```

But the Service says:

``` yaml
selector:
  app: web
```

The Service is looking for:

``` text
app=web
```

But the Pods have:

``` text
app=nginx
```

Result:

``` text
Service
   |
   | selector: app=web
   |
   X
   |
No matching Pods
```

The Service exists, but it has no useful backends.

This is one of the first things to check when a Service does not work.

------------------------------------------------------------------------

# 21. Troubleshooting a Service

Start with the Pods:

``` bash
kubectl get pods
```

Check their labels:

``` bash
kubectl get pods --show-labels
```

Check the Service:

``` bash
kubectl get svc
```

Describe it:

``` bash
kubectl describe svc nginx-service
```

Check endpoints:

``` bash
kubectl get endpoints nginx-service
```

Check EndpointSlices:

``` bash
kubectl get endpointslices
```

Then verify:

``` text
Service selector
        ↓
Pod labels
        ↓
Matching Pods
        ↓
Endpoints / EndpointSlices
        ↓
Connectivity
```

If endpoints are empty, investigate the selector and Pod labels first.

------------------------------------------------------------------------

# 22. Testing the Service

Run a temporary client Pod:

``` bash
kubectl run curl \
  --image=curlimages/curl \
  -it \
  --rm \
  -- sh
```

Then:

``` bash
curl http://nginx-service
```

The request goes through the Service to one of the matching NGINX Pods.

``` text
curl Pod
    |
    | HTTP request
    v
nginx-service
    |
    +----------+----------+
    |          |          |
  NGINX      NGINX      NGINX
   Pod        Pod        Pod
```

------------------------------------------------------------------------

# 23. Is a Service a Load Balancer?

A Service can distribute traffic across matching backend Pods, but the
exact traffic handling depends on the Service type and Kubernetes
networking implementation.

For a basic mental model:

``` text
Client
   |
   v
Service
   |
   +---- Pod 1
   +---- Pod 2
   +---- Pod 3
```

The Service provides a stable abstraction over these backend Pods.

Do not confuse this with an external cloud LoadBalancer.

That is a separate Service type and deployment model.

------------------------------------------------------------------------

# 24. Deployment vs Service

  Deployment                 Service
  -------------------------- -------------------------------------
  Manages Pods               Provides access to Pods
  Maintains replicas         Selects backend Pods
  Handles replacement        Provides stable endpoint
  Performs rolling updates   Enables service discovery
  Controls desired state     Routes traffic to matching backends

Simple rule:

> **Deployment manages the application instances. Service provides
> access to them.**

------------------------------------------------------------------------

# 25. Pod vs Service

  Pod                           Service
  ----------------------------- -----------------------------------
  Runs application containers   Provides stable access
  Has an IP address             Has a stable virtual IP/DNS name
  Can be replaced               Abstracts changing Pods
  Temporary                     Designed as a stable access point

Remember:

``` text
Pod = where application runs

Service = how other applications reliably reach it
```

------------------------------------------------------------------------

# 26. Service vs Ingress

A Service provides access to Pods.

Ingress provides HTTP/HTTPS routing rules to Services, typically through
an Ingress controller.

``` text
Internet
   |
   v
Ingress
   |
   | HTTP/HTTPS routing
   v
Service
   |
   | stable access
   v
Pods
```

For example, routing could conceptually look like:

``` text
api.example.com
       |
       v
   API Service
       |
       v
   API Pods

shop.example.com
       |
       v
   Web Service
       |
       v
   Web Pods
```

Ingress and Services solve different layers of the problem.

------------------------------------------------------------------------

# 27. Three Questions for Every Service

Whenever you see a Service, ask:

### 1. What Pods does it select?

Look at:

``` yaml
selector:
```

### 2. What port does the Service expose?

Look at:

``` yaml
port:
```

### 3. Where does it send traffic?

Look at:

``` yaml
targetPort:
```

These three questions explain a large part of how a Service works.

------------------------------------------------------------------------

# 28. Complete Request Flow

Let's put everything together.

``` text
Client
  |
  | http://nginx-service
  v
Kubernetes DNS
  |
  | resolves Service name
  v
Service
  |
  | selector: app=nginx
  v
Matching Pods
  |
  +---------+---------+
  |         |         |
 Pod 1     Pod 2     Pod 3
```

The Pods may change:

``` text
Pod 1 → deleted
Pod 4 → created
```

But the application still uses:

``` text
nginx-service
```

The client does not need to track individual Pod IPs.

------------------------------------------------------------------------

# 29. Complete Example

## Deployment

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

## Service

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

Apply both:

``` bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Verify:

``` bash
kubectl get pods
kubectl get svc
kubectl get endpoints nginx-service
kubectl get endpointslices
```

Test from inside the cluster:

``` bash
kubectl run curl \
  --image=curlimages/curl \
  -it \
  --rm \
  -- sh
```

Then:

``` bash
curl http://nginx-service
```

------------------------------------------------------------------------

# 30. Service Troubleshooting Checklist

When a Service is not working, check in this order:

``` text
1. Is the Pod running?
        ↓
2. Does the Pod have the expected label?
        ↓
3. Does the Service selector match that label?
        ↓
4. Does the Service have endpoints?
        ↓
5. Is the targetPort correct?
        ↓
6. Is the application actually listening on that port?
        ↓
7. Can the client resolve the Service DNS name?
        ↓
8. Can the client connect to the Service?
        ↓
9. Is NetworkPolicy blocking the traffic?
```

Useful commands:

``` bash
kubectl get pods
kubectl get pods --show-labels
kubectl get svc
kubectl describe svc nginx-service
kubectl get endpoints nginx-service
kubectl get endpointslices
```

------------------------------------------------------------------------

# 31. Common Beginner Mistakes

### Mistake 1: Using Pod IPs directly

Pod IPs can change.

Prefer the Service.

------------------------------------------------------------------------

### Mistake 2: Selector does not match labels

Example:

``` text
Pod:
app=nginx

Service:
app=backend
```

No matching backends.

------------------------------------------------------------------------

### Mistake 3: Confusing `port` and `targetPort`

Remember:

``` text
port       → Service
targetPort → Pod
```

------------------------------------------------------------------------

### Mistake 4: Thinking `containerPort` exposes the application

`containerPort` does not create external access by itself.

------------------------------------------------------------------------

### Mistake 5: Assuming the Service creates Pods

The Deployment manages the Pods.

The Service provides access to them.

------------------------------------------------------------------------

### Mistake 6: Forgetting namespaces

A Service and the client may be in different namespaces.

Use the appropriate DNS name when necessary.

------------------------------------------------------------------------

# 32. Interview Quick Revision

### What is a Kubernetes Service?

A stable networking abstraction that provides access to a group of
matching Pods.

### Why do we need Services?

Because Pod IPs are dynamic and can change when Pods are replaced.

### How does a Service find Pods?

Using label selectors.

### What is `port`?

The port exposed by the Service.

### What is `targetPort`?

The port on the backend Pod/application receiving the traffic.

### What is `containerPort`?

A declaration describing the container's port; it does not itself expose
the application externally.

### What is ClusterIP?

The default Service type that provides an internal stable virtual IP.

### What happens when a Pod is deleted?

A Deployment can create a replacement, and the Service's backend
endpoint information updates to reflect the current matching Pods.

### Can a Service select Pods from another namespace?

Service selectors operate within the Service's namespace; a Service does
not directly select Pods in another namespace.

### What should you check if a Service has no endpoints?

Check the Service selector and the labels on the Pods.

------------------------------------------------------------------------

# 33. Final Mental Model

Keep this picture in mind:

``` text
                DEPLOYMENT
                    |
                    | manages
                    v
                  PODS
             +------+------+------+
             |      |      |      |
            Pod    Pod    Pod    Pod
             |
             | run application
             v
          APPLICATION

              SERVICE
                 |
                 | selects Pods
                 v
          +------+------+------+
          |      |      |      |
         Pod    Pod    Pod    Pod

Service
   |
   +-- Stable endpoint
   +-- Stable DNS name
   +-- Selects Pods using labels
   +-- Provides access to changing Pods
```

The most important sentence is:

> **Pods run the application. Services provide a stable way to reach
> those Pods.**

------------------------------------------------------------------------

# 34. What Comes Next

The Service concept is the foundation for several Kubernetes networking
topics:

``` text
Kubernetes Services
        ↓
ClusterIP
        ↓
NodePort
        ↓
LoadBalancer
        ↓
Kubernetes DNS
        ↓
Endpoints / EndpointSlices
        ↓
Ingress
        ↓
NetworkPolicy
        ↓
Advanced Kubernetes Networking
```

The key foundation to carry forward is simple:

``` text
Pod
 ↓
Runs the application

Service
 ↓
Provides stable access

Selector
 ↓
Finds the right Pods

DNS
 ↓
Lets applications find the Service
```

---

## 📝 Additional notes

- **Named ports:** set `targetPort: http` and name the container port `http`. You can then change the container's port number without editing the Service.
- **Sticky connections:** `sessionAffinity: ClientIP` sends a client back to the same Pod each time.
- **Services for external systems:** a Service with no selector can point at endpoints you manage yourself, and `type: ExternalName` gives a DNS alias for an external hostname.
- **Readiness matters:** Pods failing their readiness probe are removed from a Service's backends (module 26).

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
- [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)
- [Connecting applications with Services](https://kubernetes.io/docs/tutorials/services/connect-applications-service/)
- [Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
