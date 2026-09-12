# Kubernetes Ingress

Ingress is a Kubernetes API resource used to define **HTTP and HTTPS routing rules** that send incoming requests to Kubernetes Services.

This guide builds a complete Ingress setup from scratch using:

- Minikube
- Docker driver
- `ingress-nginx`
- NGINX Deployments
- ClusterIP Services
- Host-based routing
- Path-based routing
- `minikube tunnel`
- Local hostname resolution with `/etc/hosts`

---

## 1. Why Do We Need Ingress?

Consider an application with multiple components:

```text
Frontend
Backend API
Payments
Products
```

If every component needs internet access, one approach is to expose each Service separately:

```text
Frontend Service  → LoadBalancer
Backend Service   → LoadBalancer
Products Service  → LoadBalancer
Payments Service  → LoadBalancer
```

For HTTP applications, a more centralized routing model is often useful.

For example:

```text
shubhamgour.com
       ↓
frontend-service

shubhamgour.com/api
       ↓
backend-service
```

Ingress provides a way to define these HTTP/HTTPS routing rules.

---

## 2. What Is Ingress?

An **Ingress** is a Kubernetes API resource that defines rules for routing HTTP and HTTPS traffic to Services.

Ingress does **not** run the application.

The responsibilities are separated:

```text
Pods
  ↓
Run the application

Services
  ↓
Provide stable access to Pods

Ingress
  ↓
Defines HTTP/HTTPS routing rules

Ingress Controller
  ↓
Actually implements those rules
```

A typical request flow is:

```text
Internet
   ↓
Ingress Controller
   ↓
Service
   ↓
Pods
```

---

## 3. Ingress vs Ingress Controller

These are two different concepts.

### Ingress

The Ingress resource contains the routing rules.

### Ingress Controller

The Ingress Controller watches Ingress resources and actually processes incoming HTTP/HTTPS traffic according to those rules.

```text
Ingress
   ↓
Routing rules
   ↓
Ingress Controller
   ↓
HTTP/HTTPS traffic handling
   ↓
Services
   ↓
Pods
```

Creating an Ingress resource without an appropriate controller does not by itself provide a working HTTP entry point.

---

## 4. Application Architecture

Before creating the Ingress, create two simple applications:

```text
Frontend
Backend
```

Each application will have:

- a Deployment
- Pods
- a Service

NGINX is used as the application container to keep the networking concepts simple.

Final architecture:

```text
                  Ingress Controller
                         |
              +----------+----------+
              |                     |
       frontend-service      backend-service
              |                     |
       frontend Pods          backend Pods
```

---

## 5. Create the Frontend Deployment

Create:

```bash
touch frontend-deployment.yaml
```

Add:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: nginx
          ports:
            - containerPort: 80
```

Apply:

```bash
kubectl apply -f frontend-deployment.yaml
```

Check:

```bash
kubectl get pods
```

---

## 6. Create the Backend Deployment

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
          ports:
            - containerPort: 80
```

The structure is the same as the frontend Deployment.

The important difference is the label:

```text
Frontend Pods → app=frontend
Backend Pods  → app=backend
```

Apply:

```bash
kubectl apply -f backend-deployment.yaml
```

Check:

```bash
kubectl get pods --show-labels
```

---

## 7. Create the Frontend Service

Ingress normally routes traffic to **Services**, not directly to Pods.

Create:

```bash
touch frontend-service.yaml
```

Add:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
```

The port on the selected frontend Pods.

Apply:

```bash
kubectl apply -f frontend-service.yaml
```

Check:

```bash
kubectl get svc
```

---

## 8. Create the Backend Service

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
    app: backend
  ports:
    - port: 80
      targetPort: 80
```

The important difference is:

```yaml
selector:
  app: backend
```

This Service selects the backend Pods.

Apply:

```bash
kubectl apply -f backend-service.yaml
```

Check:

```bash
kubectl get svc
```

Both Services are ClusterIP Services because no other Service type was specified.

---

## 9. The Problem Ingress Solves

At this point:

```text
Frontend Pods
      ↓
Frontend Service

Backend Pods
      ↓
Backend Service
```

If both need to be externally accessible, we could expose both using LoadBalancer Services.

For HTTP applications, we may instead want a single entry point that routes based on hostname or path.

For example:

```text
shubhamgour.com
       ↓
frontend-service

shubhamgour.com/api
       ↓
backend-service
```

This is where Ingress becomes useful.

---

## 10. Install the Ingress Controller

For this setup, use the community `ingress-nginx` controller.

Check Helm:

```bash
helm version
```

Check the Kubernetes cluster:

```bash
kubectl cluster-info
kubectl get nodes
```

> The Kubernetes Ingress resource and the NGINX-based Ingress Controller are different things. The controller is the component that processes the traffic.

---

## 11. Install `ingress-nginx` Using Helm

Run:

```bash
helm upgrade --install ingress-nginx ingress-nginx   --repo https://kubernetes.github.io/ingress-nginx   --namespace ingress-nginx   --create-namespace
```

### Command Breakdown

`helm upgrade --install` installs the release if it does not exist and upgrades it if it already exists.

`ingress-nginx` is the Helm release name and chart name.

```text
--repo https://kubernetes.github.io/ingress-nginx
```

Specifies the chart repository.

```text
--namespace ingress-nginx
```

Installs the controller into the `ingress-nginx` namespace.

```text
--create-namespace
```

Creates the namespace if it does not already exist.

---

## 12. Verify the Ingress Controller

Check the namespace:

```bash
kubectl get namespace
```

Check resources:

```bash
kubectl get all -n ingress-nginx
```

Check controller Pods:

```bash
kubectl get pods -n ingress-nginx
```

Check the Deployment:

```bash
kubectl get deployment -n ingress-nginx
```

Check the Service:

```bash
kubectl get svc -n ingress-nginx
```

In this Minikube setup, the controller Service is a:

```text
LoadBalancer
```

A local Minikube LoadBalancer does not automatically mean that a cloud load balancer has been created.

The local exposure will be handled with `minikube tunnel`.

---

## 13. Understand the Architecture Before Creating the Ingress

We now have:

```text
Frontend Pods
      ↓
Frontend Service

Backend Pods
      ↓
Backend Service
```

And:

```text
Ingress Controller
```

The missing piece is the routing configuration.

That routing configuration is provided by the **Ingress resource**.

```text
Ingress
   ↓
Routing rules

Ingress Controller
   ↓
Implements those rules
```

---

## 14. Check the IngressClass

Run:

```bash
kubectl get ingressclass
```

Use the IngressClass associated with the controller you installed.

For this setup:

```text
nginx
```

Therefore the Ingress will use:

```yaml
ingressClassName: nginx
```

The exact class name can vary between environments, so always verify it with:

```bash
kubectl get ingressclass
```

---

## 15. Create the First Ingress

Create:

```bash
touch ingress.yaml
```

Use:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: application-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: shubhamgour.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

---

## 17. Apply the Ingress

Run:

```bash
kubectl apply -f ingress.yaml
```

Check:

```bash
kubectl get ingress
```

Inspect:

```bash
kubectl describe ingress application-ingress
```

The Ingress resource now exists.

The local computer still needs to know where `shubhamgour.com` should resolve.

---

## 18. Complete Request Flow

For:

```text
http://shubhamgour.com/
```

the Ingress Controller evaluates:

```text
Host: shubhamgour.com
Path: /
```

The rule says:

```text
shubhamgour.com + /
        ↓
frontend-service
```

The Service then routes to the frontend Pods.

```text
Browser
   ↓
HTTP request
   ↓
Ingress Controller
   ↓
Host + Path matching
   ↓
Frontend Service
   ↓
Service routing
   ↓
Frontend Pods
```

---

## 19. Two Separate Problems

There are two different concerns.

### Problem 1 — Reach the Ingress Controller

How does the request get to the controller?

### Problem 2 — Route the request

Once it reaches the controller, which Service should receive it?

Ingress rules mainly solve the second problem.

The first depends on how the controller is exposed.

For this Minikube setup:

```bash
minikube tunnel
```

---

## 20. Check the Ingress Controller Service

Run:

```bash
kubectl get svc -n ingress-nginx
```

Look at:

```text
TYPE
EXTERNAL-IP
```

The controller Service is expected to be:

```text
LoadBalancer
```

Initially, the external IP may be:

```text
<pending>
```

This is normal in a local Minikube environment.

---

## 21. Start Minikube Tunnel

Run in a separate terminal:

```bash
minikube tunnel
```

Keep the process running while using the local LoadBalancer.

On macOS, privileged ports such as 80 and 443 may require elevated permissions.

---

## 22. Verify the Tunnel

Run:

```bash
kubectl get svc -n ingress-nginx
```

With Minikube using the Docker driver on macOS, the controller Service may show:

```text
EXTERNAL-IP   127.0.0.1
```

The Minikube node IP can be different, for example:

```text
192.168.49.2
```

Do not assume that the Minikube node IP is the same as the LoadBalancer Service external address.

For this setup:

```text
shubhamgour.com
       ↓
127.0.0.1
       ↓
Minikube tunnel
       ↓
Ingress Controller
```

Keep the `minikube tunnel` process running.

---

## 23. Configure `/etc/hosts`

On macOS or Linux:

```bash
sudo nano /etc/hosts
```

Add:

```text
127.0.0.1 shubhamgour.com
```

Save with:

```text
Ctrl + O
Enter
Ctrl + X
```

This mapping means:

```text
shubhamgour.com
       ↓
127.0.0.1
       ↓
Minikube tunnel
       ↓
Ingress Controller
```

The `/etc/hosts` file only handles local hostname resolution.

It does not:

- create an Ingress
- create a Service
- configure Kubernetes routing

---

## 24. Verify Hostname Resolution

Check:

```bash
cat /etc/hosts
```

Confirm:

```text
127.0.0.1 shubhamgour.com
```

You can check resolution with:

```bash
ping shubhamgour.com
```

The important part is that the hostname resolves to:

```text
127.0.0.1
```

For Ingress, HTTP testing is more meaningful than ICMP ping.

Use:

```bash
curl -v http://shubhamgour.com/
```

---

## 25. Verify All Kubernetes Components

Application Pods:

```bash
kubectl get pods
```

Services:

```bash
kubectl get svc
```

Ingress:

```bash
kubectl get ingress
```

Ingress Controller Pods:

```bash
kubectl get pods -n ingress-nginx
```

Controller Service:

```bash
kubectl get svc -n ingress-nginx
```

IngressClass:

```bash
kubectl get ingressclass
```

Checklist:

```text
Applications running
        ↓
Services running
        ↓
Ingress Controller running
        ↓
Ingress resource created
        ↓
Controller externally reachable
        ↓
Hostname resolving
        ↓
HTTP request succeeds
```

---

## 26. Open the Application

Open:

```text
http://shubhamgour.com
```

The browser resolves:

```text
shubhamgour.com
        ↓
127.0.0.1
```

The request reaches the Ingress Controller.

The browser sends:

```text
Host: shubhamgour.com
```

The controller evaluates:

```text
Host: shubhamgour.com
Path: /
```

The request is routed to:

```text
frontend-service
        ↓
Frontend Pod
```

Complete flow:

```text
Browser
   ↓
http://shubhamgour.com
   ↓
/etc/hosts
   ↓
127.0.0.1
   ↓
Minikube tunnel
   ↓
Ingress Controller
   ↓
Ingress rule
   ↓
frontend-service
   ↓
Frontend Pod
```

---

## 27. Why the Hostname Must Match

These two configurations solve different problems.

### `/etc/hosts`

```text
127.0.0.1 shubhamgour.com
```

Answers:

> Where should my computer send `shubhamgour.com`?

### Ingress

```yaml
host: shubhamgour.com
```

Answers:

> Once the request reaches the Ingress Controller, what should happen to a request for `shubhamgour.com`?

Both are needed for this local hostname-based setup.

---

## 28. The HTTP Host Header

When requesting:

```text
http://shubhamgour.com
```

the HTTP request contains a Host header similar to:

```text
Host: shubhamgour.com
```

The Ingress Controller uses this hostname to select the matching rule.

```text
Host: shubhamgour.com
        ↓
Ingress rule
        ↓
frontend-service
```

When the hostname is included in the URL, the browser automatically sends the corresponding Host header.

---

## 29. Host-Based Routing

Desired routing:

```text
shubhamgour.com
        ↓
frontend-service

api.shubhamgour.com
        ↓
backend-service
```

Update `ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: application-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: shubhamgour.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80

    - host: api.shubhamgour.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 80
```

Add to `/etc/hosts`:

```text
127.0.0.1 shubhamgour.com
127.0.0.1 api.shubhamgour.com
```

Apply:

```bash
kubectl apply -f ingress.yaml
```

Test:

```text
http://shubhamgour.com
```

→ `frontend-service`

Test:

```text
http://api.shubhamgour.com
```

→ `backend-service`

Both requests use the same local Ingress endpoint.

The hostname determines the destination Service.

---

## 30. Path-Based Routing

Desired routing:

```text
shubhamgour.com/
        ↓
frontend-service

shubhamgour.com/api
        ↓
backend-service
```

Use:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: application-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: shubhamgour.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 80

          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

Routing:

```text
shubhamgour.com/api
        ↓
backend-service

shubhamgour.com/
        ↓
frontend-service
```

This is **path-based routing**.

---

## 31. Why `/api` Is More Specific Than `/`

The two paths are:

```text
/api
/
```

`/` is a broad prefix.

`/api` is more specific.

When multiple paths match, Kubernetes path matching rules include precedence based on the longest matching path.

Therefore:

```text
/api
```

takes precedence over:

```text
/
```

Keeping the more specific route first also makes the configuration easier to read.

---

## 32. Test Path-Based Routing

Ensure `/etc/hosts` contains:

```text
127.0.0.1 shubhamgour.com
```

Apply:

```bash
kubectl apply -f ingress.yaml
```

Open:

```text
http://shubhamgour.com
```

Expected:

```text
frontend-service
```

Open:

```text
http://shubhamgour.com/api
```

Expected:

```text
backend-service
```

The browser automatically sends:

```text
Host: shubhamgour.com
```

and the URL provides:

```text
/api
```

The Ingress Controller evaluates:

```text
Host = shubhamgour.com
Path = /api
```

and selects:

```text
backend-service
```

---

## 33. Verify Routing With `curl`

Frontend:

```bash
curl -v http://shubhamgour.com/
```

Backend route:

```bash
curl -v http://shubhamgour.com/api
```

Because the hostname is present in the URL, `curl` automatically uses it for the HTTP Host header.

You do not need to manually add:

```bash
-H "Host: shubhamgour.com"
```

when testing through the hostname.

---

## 34. Important NGINX Behavior

Both example applications use the standard NGINX image.

Therefore both applications may initially return the standard NGINX welcome page.

That does not mean routing is incorrect.

The routing is still:

```text
shubhamgour.com
        ↓
frontend-service
```

and:

```text
api.shubhamgour.com
        ↓
backend-service
```

In a real application, the frontend and backend would normally return different application content.

> **Important:** An Ingress path such as `/api` does not automatically mean that `/api` is removed before the request reaches the backend. Path rewriting is a separate controller-specific configuration concern. A stock NGINX server may therefore return `404 Not Found` for `/api` because it does not have an `/api` resource.

---

## 35. Troubleshooting Ingress

If:

```bash
curl http://shubhamgour.com
```

does not work, troubleshoot one layer at a time.

### 1. Hostname resolution

```bash
cat /etc/hosts
```

Confirm:

```text
127.0.0.1 shubhamgour.com
```

### 2. Controller

```bash
kubectl get pods -n ingress-nginx
```

The controller Pod should be running.

### 3. Controller exposure

```bash
kubectl get svc -n ingress-nginx
```

Check:

- Service type
- External IP
- Ports

### 4. Ingress

```bash
kubectl get ingress
```

### 5. Inspect Ingress

```bash
kubectl describe ingress application-ingress
```

### 6. Service endpoints

```bash
kubectl get endpoints
kubectl get endpointslices
```

The Services should have backend endpoints.

---

## 36. Recommended Troubleshooting Flow

```text
Hostname resolution
        ↓
Ingress Controller exposure
        ↓
Ingress Controller
        ↓
Ingress rules
        ↓
Service
        ↓
Endpoints
        ↓
Pods
```

Check each layer before changing configuration.

---

## 37. Minikube + Docker Driver + macOS

For this environment:

```text
Minikube
Docker driver
macOS
```

the Minikube node IP may look like:

```text
192.168.49.2
```

However, when the Ingress Controller is exposed as a LoadBalancer and `minikube tunnel` is running, the LoadBalancer may be exposed locally through:

```text
127.0.0.1
```

Therefore, in this setup:

```text
127.0.0.1 shubhamgour.com
```

is used in `/etc/hosts`.

Always inspect:

```bash
kubectl get svc -n ingress-nginx
```

to determine how the controller is exposed.

Also, `ping` is not a reliable test for HTTP Ingress functionality.

Prefer:

```bash
curl -v http://shubhamgour.com
```

Keep:

```bash
minikube tunnel
```

running.

---

## 38. Host-Based vs Path-Based Routing

### Host-Based Routing

```text
shubhamgour.com
        ↓
frontend-service

api.shubhamgour.com
        ↓
backend-service
```

The hostname determines the destination.

### Path-Based Routing

```text
shubhamgour.com/
        ↓
frontend-service

shubhamgour.com/api
        ↓
backend-service
```

The URL path determines the destination.

### Both Can Be Combined

```text
shubhamgour.com/
        ↓
frontend-service

shubhamgour.com/api
        ↓
backend-service

api.shubhamgour.com/
        ↓
backend-service
```

---

## 39. Ingress Does Not Replace Services

Do not think:

```text
Ingress OR Service
```

Think:

```text
Client
   ↓
Ingress Controller
   ↓
Service
   ↓
Pods
```

Ingress routes the HTTP/HTTPS request to the appropriate Service.

The Service provides stable access to the backend Pods.

They have different responsibilities and work together.

---

## 40. Ingress vs LoadBalancer Service

A LoadBalancer Service provides external exposure through load-balancing infrastructure available in the environment.

Ingress provides HTTP/HTTPS routing capabilities.

Separate LoadBalancer Services could look like:

```text
LoadBalancer → Frontend
LoadBalancer → Backend
LoadBalancer → Payments
```

An Ingress architecture can centralize HTTP routing:

```text
                 Ingress Controller
                    /     |                         /      |                         ↓       ↓        ↓
             Frontend   Backend  Payments
              Service   Service   Service
```

Routing can be based on:

```text
Host
```

or:

```text
Path
```

For example:

```text
shubhamgour.com
        ↓
frontend-service

api.shubhamgour.com
        ↓
backend-service

shubhamgour.com/payments
        ↓
payments-service
```

Ingress still requires an Ingress Controller, and the controller still needs an appropriate external exposure mechanism.

---

## 41. When Should You Use Ingress?

Ingress is useful when you have HTTP/HTTPS applications and need:

- Hostname-based routing
- Path-based routing
- Centralized external HTTP/HTTPS entry
- Routing traffic to multiple Services

For example:

```text
shubhamgour.com
        ↓
frontend-service

api.shubhamgour.com
        ↓
backend-service

shubhamgour.com/payments
        ↓
payments-service
```

Ingress centralizes HTTP routing while Services continue providing stable access to Pods.

---

## 42. Ingress vs Service — Final Difference

A Service answers:

> **How do I provide stable access to my Pods?**

Ingress answers:

> **How do I route incoming HTTP or HTTPS requests to the correct Service?**

The relationship is:

```text
Ingress
   ↓
Service
   ↓
Pods
```

---

## 43. Interview Questions

### 1. What is Ingress in Kubernetes?

Ingress is a Kubernetes API resource that defines HTTP and HTTPS routing rules to Services.

### 2. Does Ingress directly route traffic to Pods?

Typically, Ingress routes traffic to Services, which then provide access to Pods.

### 3. What is an Ingress Controller?

An Ingress Controller is the component that implements and processes Ingress rules and handles the actual traffic.

### 4. Can I create an Ingress without an Ingress Controller?

The Ingress resource can exist, but without an appropriate controller there may be nothing processing those rules.

### 5. What is host-based routing?

Routing traffic based on the hostname.

Example:

```text
shubhamgour.com
api.shubhamgour.com
```

### 6. What is path-based routing?

Routing traffic based on the URL path.

Example:

```text
shubhamgour.com/
shubhamgour.com/api
```

### 7. Does Ingress replace a Service?

No.

Ingress and Services have different responsibilities.

### 8. Can Ingress provide HTTPS?

Yes. TLS can be configured through the Ingress and supported by the Ingress Controller.

### 9. Does Ingress automatically provide DNS?

No.

DNS is normally configured separately.

For this local setup, `/etc/hosts` provides local hostname resolution.

### 10. Does Ingress automatically provide a public IP?

Not necessarily.

External exposure depends on how the Ingress Controller is deployed and exposed.

### 11. Why was `minikube tunnel` used?

Because the Ingress Controller Service is a LoadBalancer Service, while Minikube is a local environment rather than a cloud provider that automatically provisions a cloud load balancer.

### 12. Why was `127.0.0.1 shubhamgour.com` added to `/etc/hosts`?

In this Minikube Docker-driver setup on macOS, the tunnel exposes the LoadBalancer locally through `127.0.0.1`.

### 13. Why can't I simply use the Minikube IP?

The Minikube node IP and the external address of a LoadBalancer Service are not necessarily the same.

Check:

```bash
kubectl get svc -n ingress-nginx
```

---

## 44. Complete Practical Checklist

### Check Minikube

```bash
minikube status
```

### Check nodes

```bash
kubectl get nodes
```

### Create frontend

```bash
kubectl apply -f frontend-deployment.yaml
```

### Create backend

```bash
kubectl apply -f backend-deployment.yaml
```

### Create frontend Service

```bash
kubectl apply -f frontend-service.yaml
```

### Create backend Service

```bash
kubectl apply -f backend-service.yaml
```

### Install Ingress Controller

```bash
helm upgrade --install ingress-nginx ingress-nginx   --repo https://kubernetes.github.io/ingress-nginx   --namespace ingress-nginx   --create-namespace
```

### Verify controller

```bash
kubectl get pods -n ingress-nginx
```

### Check IngressClass

```bash
kubectl get ingressclass
```

### Create Ingress

```bash
kubectl apply -f ingress.yaml
```

### Check Ingress

```bash
kubectl get ingress
```

### Start tunnel

```bash
minikube tunnel
```

Keep it running.

### Check controller Service

```bash
kubectl get svc -n ingress-nginx
```

If the local LoadBalancer is exposed through:

```text
127.0.0.1
```

add:

```text
127.0.0.1 shubhamgour.com
```

to `/etc/hosts`.

### Test HTTP

```bash
curl -v http://shubhamgour.com
```

### Browser

```text
http://shubhamgour.com
```

### Path-based routing

```text
http://shubhamgour.com/
```

→ `frontend-service`

```text
http://shubhamgour.com/api
```

→ `backend-service`

---

## 45. Complete Architecture

For path-based routing:

```text
                         Browser
                            |
                            | http://shubhamgour.com/api
                            |
                            v
                      /etc/hosts
                            |
                            | shubhamgour.com → 127.0.0.1
                            |
                            v
                    Minikube tunnel
                            |
                            v
                  Ingress Controller
                            |
                            | Host + Path routing
                            |
                            v
                    backend-service
                            |
                            v
                       Backend Pods
```

For the frontend:

```text
Browser
   |
   | http://shubhamgour.com/
   v
/etc/hosts
   |
   v
127.0.0.1
   |
   v
Minikube tunnel
   |
   v
Ingress Controller
   |
   v
frontend-service
   |
   v
Frontend Pods
```

---

## 46. Responsibilities of Each Component

| Component | Responsibility |
|---|---|
| Pod | Runs the application |
| Deployment | Manages application Pods |
| Service | Provides stable access to Pods |
| Ingress | Defines HTTP/HTTPS routing rules |
| Ingress Controller | Implements the Ingress rules and handles traffic |
| IngressClass | Associates an Ingress with a controller |
| `/etc/hosts` | Provides local hostname resolution |
| Minikube tunnel | Makes the local LoadBalancer reachable in this setup |

The incoming traffic flow is:

```text
Client
   ↓
Ingress Controller
   ↓
Service
   ↓
Pods
```

---

## 47. Cleanup

Delete the Ingress:

```bash
kubectl delete -f ingress.yaml
```

Delete Services:

```bash
kubectl delete -f frontend-service.yaml
kubectl delete -f backend-service.yaml
```

Delete Deployments:

```bash
kubectl delete -f frontend-deployment.yaml
kubectl delete -f backend-deployment.yaml
```

Uninstall the Ingress Controller:

```bash
helm uninstall ingress-nginx -n ingress-nginx
```

Delete the namespace if required:

```bash
kubectl delete namespace ingress-nginx
```

Remove the local hostname entries from:

```bash
sudo nano /etc/hosts
```

Remove:

```text
127.0.0.1 shubhamgour.com
```

If added:

```text
127.0.0.1 api.shubhamgour.com
```

remove that as well.

Stop the tunnel with:

```text
Ctrl + C
```

---

## 48. Key Takeaways

1. **Ingress is a Kubernetes API resource.**
2. **Ingress defines HTTP and HTTPS routing rules.**
3. **Ingress normally routes traffic to Services, not directly to Pods.**
4. **An Ingress Controller actually implements the rules.**
5. **Ingress does not replace Services.**
6. **Host-based routing uses hostnames.**
7. **Path-based routing uses URL paths.**
8. **Ingress does not automatically provide DNS.**
9. **Ingress does not automatically provide a public IP.**
10. **External exposure depends on the environment.**
11. **In this Minikube Docker-driver setup on macOS, `minikube tunnel` exposes the LoadBalancer locally.**
12. **`/etc/hosts` provides local hostname resolution.**
13. **For HTTP Ingress, test HTTP/HTTPS connectivity rather than relying on ICMP ping.**
14. **`/api` does not automatically get stripped from the request path.**
15. **Pods, Services, Ingress, and the Ingress Controller each have different responsibilities.**

## Final Mental Model

```text
                 HTTP / HTTPS
                      |
                      v
              Ingress Controller
                      |
               Host + Path rules
                      |
          +-----------+-----------+
          |                       |
          v                       v
   Frontend Service        Backend Service
          |                       |
          v                       v
   Frontend Pods            Backend Pods
```

> **Services provide stable access to Pods. Ingress provides HTTP/HTTPS routing to those Services. The Ingress Controller implements those routing rules.**
