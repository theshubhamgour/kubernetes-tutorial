# ClusterIP vs NodePort vs LoadBalancer

Kubernetes Services provide a stable way to access Pods, but the way a
Service is exposed depends on the application's networking requirements.

This guide covers:

-   **ClusterIP** --- internal cluster access
-   **NodePort** --- external access through a Kubernetes node port
-   **LoadBalancer** --- external load-balancing integration when
    supported by the environment

The examples use NGINX and build everything step by step.

------------------------------------------------------------------------

## 1. The Problem

Pods are temporary and their IP addresses can change.

A Service provides stable access to Pods, but applications have
different exposure requirements.

For example:

-   A backend may only need to be accessed by other Pods.
-   A development application may need simple external access through a
    node.
-   A production application may need an external load balancer.

The key question is:

> **Who needs to access the application, and how should the traffic
> enter Kubernetes?**

------------------------------------------------------------------------

## 2. The Three Service Types

  -----------------------------------------------------------------------
  Service Type            Primary Use             External Access
  ----------------------- ----------------------- -----------------------
  **ClusterIP**           Internal services       Not normally

  **NodePort**            Simple external access  Yes
                          through nodes           

  **LoadBalancer**        External load-balancing Yes, when supported
                          integration             
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 3. Create the Application

Create `deployment.yaml`:

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

### YAML explanation

-   `apiVersion: apps/v1` --- uses the `apps/v1` API for the Deployment.
-   `kind: Deployment` --- creates a Deployment.
-   `metadata.name` --- names the Deployment `nginx`.
-   `spec` --- defines the desired Deployment configuration.
-   `replicas: 3` --- requests three Pods.
-   `selector.matchLabels.app: nginx` --- tells the Deployment which
    Pods it manages.
-   `template` --- defines the Pod template.
-   `template.metadata.labels.app: nginx` --- gives each Pod the
    `app=nginx` label.
-   `containers` --- defines the containers in the Pod.
-   `name: nginx` --- names the container.
-   `image: nginx` --- uses the NGINX image.
-   `containerPort: 80` --- describes the port used by NGINX.

> `containerPort` does not by itself expose the application outside the
> Pod.

Apply the Deployment:

``` bash
kubectl apply -f deployment.yaml
```

Check the Pods:

``` bash
kubectl get pods -o wide
```

Each Pod receives its own IP, but Pod IPs should not be treated as
permanent addresses.

------------------------------------------------------------------------

# 4. ClusterIP

ClusterIP is the default Kubernetes Service type.

Create `clusterip.yaml`:

``` yaml
apiVersion: v1
kind: Service

metadata:
  name: nginx-clusterip

spec:
  type: ClusterIP

  selector:
    app: nginx

  ports:
    - port: 80
      targetPort: 80
```

### YAML explanation

-   `apiVersion: v1` --- Services use the core Kubernetes API.
-   `kind: Service` --- creates a Service.
-   `metadata.name` --- names the Service `nginx-clusterip`.
-   `spec` --- contains the Service configuration.
-   `type: ClusterIP` --- creates a ClusterIP Service.
-   `selector.app: nginx` --- selects Pods with the `app=nginx` label.
-   `ports` --- defines the Service ports.
-   `port: 80` --- the port exposed by the Service.
-   `targetPort: 80` --- the port on the backend Pod/application.

For this example:

``` text
Service port = 80
Pod port     = 80
```

Apply:

``` bash
kubectl apply -f clusterip.yaml
```

Check:

``` bash
kubectl get svc
```

A ClusterIP Service provides a stable internal endpoint.

------------------------------------------------------------------------

# 5. Test ClusterIP

Create a temporary client Pod:

``` bash
kubectl run curl   --image=curlimages/curl   -it   --rm   -- sh
```

Inside the Pod:

``` bash
curl http://nginx-clusterip
```

The request reaches the Service and is sent to one of the matching NGINX
Pods.

Exit:

``` bash
exit
```

ClusterIP is intended primarily for internal cluster communication.

------------------------------------------------------------------------

# 6. Why ClusterIP Is Not the Normal Public Endpoint

A normal ClusterIP Service is designed for access from inside the
cluster.

For example:

``` text
Application inside cluster
        |
        v
ClusterIP Service
        |
        v
NGINX Pods
```

If users outside the cluster need access, another exposure mechanism is
required.

That brings us to NodePort.

------------------------------------------------------------------------

# 7. NodePort

NodePort exposes a Service through a port on Kubernetes nodes.

Create `nodeport.yaml`:

``` yaml
apiVersion: v1
kind: Service

metadata:
  name: nginx-nodeport

spec:
  type: NodePort

  selector:
    app: nginx

  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

### YAML explanation

-   `apiVersion: v1` --- uses the core Kubernetes API.
-   `kind: Service` --- creates a Service.
-   `metadata.name` --- names the Service `nginx-nodeport`.
-   `spec` --- contains the Service configuration.
-   `type: NodePort` --- exposes the Service through a node port.
-   `selector.app: nginx` --- selects the NGINX Pods.
-   `port: 80` --- the Service port.
-   `targetPort: 80` --- the backend Pod/application port.
-   `nodePort: 30080` --- the port exposed on the Kubernetes nodes.

For this example:

``` text
NodePort   = 30080
Service    = 80
Pod        = 80
```

Apply:

``` bash
kubectl apply -f nodeport.yaml
```

Check:

``` bash
kubectl get svc
```

You may see:

``` text
NAME              TYPE       CLUSTER-IP   PORT(S)
nginx-nodeport    NodePort   10.x.x.x     80:30080/TCP
```

The `80:30080` output represents the Service port and NodePort.

------------------------------------------------------------------------

# 8. Understanding NodePort Traffic

Suppose a Kubernetes node has:

``` text
192.168.1.10
```

and the NodePort is:

``` text
30080
```

A client can conceptually connect to:

``` text
192.168.1.10:30080
```

The request enters through the node port and is handled by the Service.

The Service then routes traffic to one of the matching Pods.

The client connects to the node, not directly to a Pod IP.

------------------------------------------------------------------------

# 9. NodePort on Multiple Nodes

Suppose the cluster has:

``` text
Node 1
Node 2
Node 3
```

The NodePort provides a node-level entry point for the Service.

The backend Pods can be distributed across the cluster.

The Pod receiving the request does not necessarily have to be running on
the same node that initially received the NodePort traffic.

------------------------------------------------------------------------

# 10. NodePort Range

Kubernetes normally uses a configured NodePort range.

In a default Kubernetes configuration, the commonly used range is:

``` text
30000-32767
```

Therefore:

``` yaml
nodePort: 30080
```

is a typical example.

The actual range can be changed through Kubernetes configuration.

------------------------------------------------------------------------

# 11. Do I Need to Specify `nodePort`?

No.

You can omit it:

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

Kubernetes can automatically allocate a NodePort.

Check it with:

``` bash
kubectl get svc
```

------------------------------------------------------------------------

# 12. Why NodePort Is Not Always the Final Production Endpoint

NodePort is useful for:

-   learning
-   labs
-   development
-   testing
-   simple external integrations

But an endpoint such as:

``` text
http://NODE-IP:30080
```

is usually not the user-friendly endpoint desired for a production
application.

For production, an external load-balancing or ingress solution is
commonly used.

This leads to LoadBalancer.

------------------------------------------------------------------------

# 13. LoadBalancer

A LoadBalancer Service is designed to expose a Service externally
through load-balancing infrastructure when the Kubernetes environment
supports it.

Create `loadbalancer.yaml`:

``` yaml
apiVersion: v1
kind: Service

metadata:
  name: nginx-loadbalancer

spec:
  type: LoadBalancer

  selector:
    app: nginx

  ports:
    - port: 80
      targetPort: 80
```

### YAML explanation

-   `apiVersion: v1` --- uses the core Kubernetes API.
-   `kind: Service` --- creates a Service.
-   `metadata.name` --- names the Service `nginx-loadbalancer`.
-   `spec` --- contains the Service configuration.
-   `type: LoadBalancer` --- requests external load-balancing
    integration when supported.
-   `selector.app: nginx` --- selects the NGINX Pods.
-   `port: 80` --- the Service port.
-   `targetPort: 80` --- the backend Pod/application port.

Apply:

``` bash
kubectl apply -f loadbalancer.yaml
```

Check:

``` bash
kubectl get svc
```

In an environment with external load-balancer integration, you may see:

``` text
NAME                  TYPE           CLUSTER-IP   EXTERNAL-IP
nginx-loadbalancer    LoadBalancer   10.x.x.x     203.x.x.x
```

The exact result depends on the Kubernetes environment.

------------------------------------------------------------------------

# 14. LoadBalancer Does Not Always Give a Public IP

Creating:

``` yaml
type: LoadBalancer
```

does not guarantee that every Kubernetes installation immediately
provides a public IP.

In a managed cloud environment, Kubernetes can integrate with cloud
load-balancing infrastructure.

In a local cluster, there may be no external load-balancer
implementation.

You may therefore see:

``` text
EXTERNAL-IP   <pending>
```

Always consider the environment when troubleshooting LoadBalancer
Services.

------------------------------------------------------------------------

# 15. Compare the Three YAML Configurations

## ClusterIP

``` yaml
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

## NodePort

``` yaml
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

## LoadBalancer

``` yaml
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

The selector is the same in all three cases:

``` yaml
selector:
  app: nginx
```

All three Services can therefore select the same NGINX Pods.

The major difference is how the Service is exposed.

------------------------------------------------------------------------

# 16. Understanding `port`, `targetPort`, and `nodePort`

For:

``` yaml
ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

we have three concepts.

### `port`

The Service port.

``` text
port = 80
```

### `targetPort`

The backend Pod/application port.

``` text
targetPort = 80
```

### `nodePort`

The node-level external port for a NodePort Service.

``` text
nodePort = 30080
```

The values do not have to be identical.

For example:

``` yaml
ports:
  - port: 80
    targetPort: 8080
```

means:

``` text
Service = 80
Application = 8080
```

For NodePort:

``` yaml
ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

means:

``` text
NodePort   = 30080
Service    = 80
Application = 8080
```

------------------------------------------------------------------------

# 17. Does LoadBalancer Remove the Service?

No.

LoadBalancer is itself a Kubernetes Service type.

The resource still contains:

``` yaml
kind: Service
```

The difference is:

``` yaml
type: LoadBalancer
```

A simplified flow is:

``` text
External Load Balancer
          |
          v
Kubernetes Service
          |
          v
         Pods
```

The exact traffic implementation can vary by environment.

------------------------------------------------------------------------

# 18. Does LoadBalancer Always Use NodePort?

A simplified learning model can show:

``` text
Internet
   |
   v
External Load Balancer
   |
   v
NodePort
   |
   v
Service
   |
   v
Pods
```

However, the exact implementation and traffic path depend on the
Kubernetes environment and its load-balancer integration.

The important distinction is:

> **NodePort provides a node-level external entry point, while
> LoadBalancer provides external load-balancing integration.**

------------------------------------------------------------------------

# 19. Real-World Example

Consider an e-commerce application with:

``` text
Frontend
Backend
Database
```

Users need to access the frontend.

The frontend needs to communicate with the backend.

The backend needs to communicate with the database.

We don't need to expose everything publicly.

A possible design is:

``` text
Frontend → LoadBalancer

Backend → ClusterIP

Database → ClusterIP
```

The important principle is:

> **Expose only what actually needs external access.**

Internal services can remain internal while still being accessible to
the applications that need them.

------------------------------------------------------------------------

# 20. When to Use ClusterIP

Use ClusterIP when the application needs internal cluster access.

Common examples:

-   backend APIs
-   databases
-   internal microservices
-   internal application components
-   internal queues

Example:

``` text
Frontend Pod
      |
      v
Backend ClusterIP Service
      |
      v
Backend Pods
```

------------------------------------------------------------------------

# 21. When to Use NodePort

Use NodePort when you need external access through Kubernetes nodes.

Common examples:

-   labs
-   development
-   testing
-   simple external integrations

Example:

``` text
Client
   |
   v
NodeIP:30080
   |
   v
NodePort Service
   |
   v
Pods
```

------------------------------------------------------------------------

# 22. When to Use LoadBalancer

Use LoadBalancer when:

-   the application needs external access
-   your Kubernetes environment supports external load-balancing
    integration
-   you want an externally reachable Service through that infrastructure

Example:

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

------------------------------------------------------------------------

# 23. Inspect the Services

List Services:

``` bash
kubectl get svc
```

Inspect ClusterIP:

``` bash
kubectl describe svc nginx-clusterip
```

Inspect NodePort:

``` bash
kubectl describe svc nginx-nodeport
```

Inspect LoadBalancer:

``` bash
kubectl describe svc nginx-loadbalancer
```

Check endpoints:

``` bash
kubectl get endpoints
```

Check EndpointSlices:

``` bash
kubectl get endpointslices
```

Check Pod labels:

``` bash
kubectl get pods --show-labels
```

These commands help verify that the Services are selecting the intended
backend Pods.

------------------------------------------------------------------------

# 24. Troubleshooting: Selector Mismatch

Suppose the Pod has:

``` yaml
labels:
  app: nginx
```

but the Service has:

``` yaml
selector:
  app: backend
```

The Service is looking for:

``` text
app=backend
```

while the Pods have:

``` text
app=nginx
```

There are no matching Pods.

Check:

``` bash
kubectl get pods --show-labels
```

Then:

``` bash
kubectl describe svc <service-name>
```

And:

``` bash
kubectl get endpoints <service-name>
```

If the endpoints are empty, check the selector and Pod labels first.

------------------------------------------------------------------------

# 25. Troubleshooting: Wrong `targetPort`

Suppose the application listens on:

``` text
8080
```

but the Service has:

``` yaml
targetPort: 80
```

The Service sends traffic to port 80, while the application is listening
on 8080.

The request can therefore fail.

Remember:

``` text
port
  ↓
Service

targetPort
  ↓
Application/Pod
```

Always verify the port on which the application is actually listening.

------------------------------------------------------------------------

# 26. Troubleshooting LoadBalancer

If a LoadBalancer Service shows:

``` text
EXTERNAL-IP   <pending>
```

check the Kubernetes environment.

Useful commands:

``` bash
kubectl get svc
kubectl describe svc nginx-loadbalancer
```

The issue may be related to external load-balancer integration rather
than the Service selector or application.

------------------------------------------------------------------------

# 27. Production Design Principle

Suppose we have:

``` text
Frontend → Backend → Database
```

A common mistake is to expose all three using LoadBalancer Services.

That creates unnecessary external exposure.

Instead:

``` text
Frontend → externally accessible

Backend → ClusterIP

Database → ClusterIP
```

The backend and database remain internal while still being accessible to
the applications that need them.

The goal is not to expose everything.

The goal is to expose only what needs to be exposed.

------------------------------------------------------------------------

# 28. Interview Questions

### What is the default Kubernetes Service type?

ClusterIP.

### What is ClusterIP used for?

Stable internal access to a group of Pods.

### What is NodePort?

A Service type that exposes the Service through a port on Kubernetes
nodes.

### What is LoadBalancer?

A Service type that requests external load-balancing integration when
supported by the environment.

### What is the difference between `port` and `targetPort`?

`port` is the Service port.

`targetPort` is the port on the backend Pod/application.

### What is `nodePort`?

The port exposed on Kubernetes nodes for a NodePort Service.

### Does NodePort create a new Pod?

No.

It exposes the Service through a node-level port.

### Does LoadBalancer replace the Service?

No.

LoadBalancer is a type of Kubernetes Service.

### Does every application need a LoadBalancer?

No.

Internal applications commonly use ClusterIP.

### Why might a Service have no endpoints?

Check:

-   Service selector
-   Pod labels
-   Pod readiness
-   Pod availability

### Can `port` and `targetPort` be different?

Yes.

For example:

``` yaml
port: 80
targetPort: 8080
```

------------------------------------------------------------------------

# 29. Hands-On Commands

## Check the Deployment

``` bash
kubectl get deployment
kubectl get pods -o wide
```

## Create Services

``` bash
kubectl apply -f clusterip.yaml
kubectl apply -f nodeport.yaml
kubectl apply -f loadbalancer.yaml
```

## Check Services

``` bash
kubectl get svc
```

## Inspect Services

``` bash
kubectl describe svc nginx-clusterip
kubectl describe svc nginx-nodeport
kubectl describe svc nginx-loadbalancer
```

## Check Backends

``` bash
kubectl get endpoints
kubectl get endpointslices
```

## Check Pod Labels

``` bash
kubectl get pods --show-labels
```

## Test ClusterIP

``` bash
kubectl run curl   --image=curlimages/curl   -it   --rm   -- sh
```

Then:

``` bash
curl http://nginx-clusterip
```

Exit:

``` bash
exit
```

------------------------------------------------------------------------

# 30. Cleanup

Remove the Deployment:

``` bash
kubectl delete -f deployment.yaml
```

Remove the ClusterIP Service:

``` bash
kubectl delete -f clusterip.yaml
```

Remove the NodePort Service:

``` bash
kubectl delete -f nodeport.yaml
```

Remove the LoadBalancer Service:

``` bash
kubectl delete -f loadbalancer.yaml
```

------------------------------------------------------------------------

# 31. Key Takeaways

### ClusterIP

Internal Service access.

### NodePort

External access through a Kubernetes node port.

### LoadBalancer

External access through load-balancing infrastructure when supported.

The most important decision is:

> **Choose the Service type based on how the application needs to be
> accessed.**

Internal applications generally use ClusterIP.

NodePort is useful for node-level external access, especially in simple
or testing environments.

LoadBalancer is useful when external load-balancing integration is
available and the application needs external access.

---

## 📝 Additional notes

- **Preserving the client IP:** with the default `externalTrafficPolicy: Cluster`, traffic may hop to another node and your app may not see the real client IP. `Local` preserves it, but only nodes running a backend Pod can serve traffic.
- **LoadBalancer without a cloud:** on bare metal, a `LoadBalancer` Service stays in `<pending>` until something implements it, such as MetalLB. On Minikube, `minikube tunnel` plays this role.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Service types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)
- [Create an external load balancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/)
- [Source IP with Services](https://kubernetes.io/docs/tutorials/services/source-ip/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
