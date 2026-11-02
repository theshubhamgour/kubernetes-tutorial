# Gateway API in Kubernetes

A complete beginner-friendly hands-on tutorial.

## 1. Introduction

Before Gateway API, we already learned about:

- Pods
- Services
- ClusterIP
- NodePort
- LoadBalancer
- Ingress

Today we are learning a newer and more modern way to manage traffic into a Kubernetes cluster: Gateway API.

We will start by understanding the real problem and then move to the solution.

We also need to understand one important concept that appears before Gateway API:

- Annotations

So before we jump into Gateway API, we will:

1. Build a simple frontend + backend app
2. Route it using Ingress
3. Use annotations to rewrite a path
4. See the limitation of controller-specific annotations
5. Then switch to Gateway API

---

## 2. The Problem We Are Solving

Imagine we have two applications running in Kubernetes:

- Frontend
- Backend

and they are exposed through services:

- frontend-service
- backend-service

We want:

- shubhamgour.com -> frontend-service
- shubhamgour.com/api -> backend-service

Ingress can solve this in many cases.

But now imagine the backend app does not understand `/api`; it only understands `/`.

Then routing alone is not enough. The path must sometimes be rewritten before it reaches the backend.

This is where annotations come in.

---

## 3. Demo Setup

We will create:

- a frontend deployment
- a backend deployment
- a frontend service
- a backend service
- an ingress controller
- a hostname in `/etc/hosts`
- an ingress using annotations
- then a Gateway API-based solution using Envoy Gateway

---

## 4. Create the Frontend Deployment

Create the file:

```bash
touch frontend-deployment.yaml
```

Add the following content:

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

Apply it:

```bash
kubectl apply -f frontend-deployment.yaml
```

Check the pods:

```bash
kubectl get pods
kubectl get pods -o wide
```

---

## 5. Create the Backend Deployment

```bash
touch backend-deployment.yaml
```

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

Apply it:

```bash
kubectl apply -f backend-deployment.yaml
```

Check:

```bash
kubectl get pods
kubectl get pods --show-labels
```

---

## 6. Create the Frontend Service

```bash
touch frontend-service.yaml
```

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

Apply:

```bash
kubectl apply -f frontend-service.yaml
```

Verify:

```bash
kubectl get svc
kubectl get endpoints frontend-service
```

---

## 7. Create the Backend Service

```bash
touch backend-service.yaml
```

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

Apply:

```bash
kubectl apply -f backend-service.yaml
```

Verify:

```bash
kubectl get svc
kubectl get endpoints backend-service
```

At this point:

- frontend-service -> frontend pods
- backend-service -> backend pods

---

## 8. Install the NGINX Ingress Controller

We need an Ingress controller because the Ingress resource itself is only configuration; a controller is what makes it work.

Install NGINX Ingress using Helm:

```bash
helm install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

Wait for the controller to become ready:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

Check:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

## 9. Start Minikube Tunnel

Because we are using Minikube locally, the LoadBalancer service must be accessible from the local machine.

Open another terminal and run:

```bash
minikube tunnel
```

If prompted for a password, enter it.

Then check the external address:

```bash
kubectl get svc -n ingress-nginx
```

You may see something like `127.0.0.1` in the `EXTERNAL-IP` column.

---

## 10. Configure /etc/hosts

We want to use a real hostname locally.

Open `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add:

```bash
127.0.0.1 shubhamgour.com
```

Save and verify:

```bash
cat /etc/hosts
```

Now `shubhamgour.com` resolves to `127.0.0.1`.

---

## 11. Create a Basic Ingress

```bash
touch ingress.yaml
```

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

Apply:

```bash
kubectl apply -f ingress.yaml
```

Check:

```bash
kubectl get ingress
kubectl describe ingress application-ingress
```

Test the route:

```bash
curl -v http://shubhamgour.com
```

You should get the default NGINX welcome page.

---

## 12. Add the Backend Route

Update the Ingress to include `/api`:

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

Apply the change:

```bash
kubectl apply -f ingress.yaml
```

Then test:

```bash
curl -v http://shubhamgour.com/
curl -v http://shubhamgour.com/api
```

The root route should work, but `/api` may return `404 Not Found`.

---

## 13. Why Does /api Return 404?

The Ingress can route `/api` to the backend service correctly.

However, the backend app is still just a normal NGINX server, and it does not automatically serve content at `/api`.

This means:

- request arrives at ingress
- ingress forwards to backend-service
- backend NGINX receives the request
- NGINX responds with `404` because `/api` is not configured there

The route is correct, but the application behavior is not.

---

## 14. What Is an Annotation?

An annotation is simply an extra instruction attached to a Kubernetes object.

It is not used for selecting objects like labels are.

Instead, it gives extra information or instructions to a controller.

For example, we can tell the NGINX Ingress controller:

> When you see `/api`, rewrite it before sending the request to the backend.

This is exactly what an annotation can do.

### Annotation vs Label

- Label: helps identify and select resources
- Annotation: gives extra instructions or metadata

---

## 15. Create the Annotation Ingress

Delete the previous ingress:

```bash
kubectl delete -f ingress.yaml
```

Create a new file:

```bash
touch annotation-ingress.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: annotation-demo
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: shubhamgour.com
      http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: backend-service
                port:
                  number: 80
```

Apply it:

```bash
kubectl apply -f annotation-ingress.yaml
```

Check:

```bash
kubectl get ingress
kubectl describe ingress annotation-demo
```

Notice the annotations:

- `use-regex: true`
- `rewrite-target: /$2`

These are NGINX-specific instructions.

---

## 16. What Is This Annotation Doing?

This annotation tells the controller:

- use a regex-based path match
- rewrite `/api` to `/` before sending to the backend

So:

```text
Incoming request: /api

Ingress Controller:
  sees /api
  rewrites it to /
  forwards it to backend-service

Backend NGINX:
  receives /
  serves its default page
```

This works even though the backend app itself still does not understand `/api`.

---

## 17. Test the Annotation

```bash
curl -v http://shubhamgour.com/api
```

This time, it should return `200 OK`.

This proves that the Ingress controller changed the request path before forwarding it.

---

## 18. Why Is This a Problem?

This works only because we are using the NGINX Ingress controller and know its specific annotation syntax.

If we switch to a different Ingress controller tomorrow, the annotation may no longer work.

So the key idea is:

> This instruction is understood by this specific controller.

This makes the configuration controller-specific and less portable.

---

## 19. Why Gateway API?

As applications become more complex, we do not want important routing behavior hidden in controller-specific instructions.

We want a standard Kubernetes-native way to describe traffic behavior.

This is the reason Gateway API exists.

Gateway API gives us a common, portable way to describe:

- how traffic enters the cluster
- which Gateway should handle it
- where requests should be routed

---

## 20. Gateway API Concepts

Gateway API is not a single resource. It has multiple objects.

The most important ones for us are:

- GatewayClass
- Gateway
- HTTPRoute

### GatewayClass

Tells us:

> Who manages the Gateway?

Example:

- We are using Envoy Gateway
- So the GatewayClass tells Kubernetes that Envoy Gateway is the controller

### Gateway

Tells us:

> Where does traffic enter?

Example:

- HTTP on port 80
- host: shubhamgour.com

### HTTPRoute

Tells us:

> Where should the request go?

Example:

- `/` -> frontend-service
- `/api` -> backend-service

---

## 21. Remove the Ingress Demo

Before installing Gateway API, clean up the earlier example.

Delete the annotation ingress:

```bash
kubectl delete -f annotation-ingress.yaml
```

Uninstall NGINX Ingress:

```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

Stop the minibike tunnel terminal:

```bash
Ctrl + C
```

Now we are ready for Gateway API.

---

## 22. Install Envoy Gateway

We will use Envoy Gateway as our Gateway API implementation.

Check Helm:

```bash
helm version
```

Install Envoy Gateway:

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.9.1 \
  -n envoy-gateway-system \
  --create-namespace
```

Wait for the deployment to be available:

```bash
kubectl wait --timeout=5m \
  -n envoy-gateway-system \
  deployment/envoy-gateway \
  --for=condition=Available
```

Check:

```bash
kubectl get pods -n envoy-gateway-system
```

---

## 23. Verify Gateway API Resources

Check if Gateway API CRDs are installed:

```bash
kubectl api-resources | grep gateway.networking.k8s.io
kubectl get crd | grep gateway.networking.k8s.io
```

You should see resources such as:

- gatewayclasses
- gateways
- httproutes

---

## 24. Create a GatewayClass

Create a file:

```bash
touch gatewayclass.yaml
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

Apply it:

```bash
kubectl apply -f gatewayclass.yaml
```

Check:

```bash
kubectl get gatewayclass
kubectl describe gatewayclass eg
```

The GatewayClass should be accepted.

---

## 25. Create a Gateway

```bash
touch gateway.yaml
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 80
```

Apply:

```bash
kubectl apply -f gateway.yaml
```

Check:

```bash
kubectl get gateway
kubectl describe gateway eg
```

This Gateway is the entry point for HTTP traffic on port 80.

---

## 26. What Happens Behind the Scenes?

We did not manually create an Envoy proxy.

Instead, we created a `Gateway` resource and the controller watched it.

Because the Gateway is linked to `GatewayClass: eg`, Envoy Gateway creates and configures the required infrastructure automatically.

This is a standard Kubernetes pattern:

- user describes desired state
- controller makes it happen

---

## 27. Create the Frontend Application

```bash
touch frontend-deployment.yaml
```

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

Create the service:

```bash
touch frontend-service.yaml
```

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

Apply:

```bash
kubectl apply -f frontend-service.yaml
```

Check:

```bash
kubectl get svc
kubectl get endpoints frontend-service
```

---

## 28. Create the Backend Application

```bash
touch backend-deployment.yaml
```

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

Apply:

```bash
kubectl apply -f backend-deployment.yaml
```

Create the service:

```bash
touch backend-service.yaml
```

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

Apply:

```bash
kubectl apply -f backend-service.yaml
```

Check:

```bash
kubectl get svc
kubectl get endpoints backend-service
```

---

## 29. Create the First HTTPRoute

```bash
touch httproute.yaml
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
spec:
  parentRefs:
    - name: eg
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: frontend-service
          port: 80
```

Apply:

```bash
kubectl apply -f httproute.yaml
```

Check:

```bash
kubectl get httproute
kubectl describe httproute frontend-route
```

This attaches the route to the Gateway and sends `/` to `frontend-service`.

---

## 30. Understand parentRefs and backendRefs

### parentRefs

This tells the route:

> Which Gateway should I attach to?

In our case:

```yaml
parentRefs:
  - name: eg
```

### backendRefs

This tells the route:

> Where should matching traffic be sent?

In our case:

```yaml
backendRefs:
  - name: frontend-service
    port: 80
```

This means:

```text
Request -> Gateway -> HTTPRoute -> frontend-service -> frontend pods
```

---

## 31. Update HTTPRoute for Frontend and Backend

Now we want two rules:

- `/api` -> backend-service
- `/` -> frontend-service

Update `httproute.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: application-route
spec:
  parentRefs:
    - name: eg
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: backend-service
          port: 80
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: frontend-service
          port: 80
```

Apply it:

```bash
kubectl apply -f httproute.yaml
```

Check status:

```bash
kubectl get httproute
kubectl describe httproute application-route
```

---

## 32. Understand the Routing Flow

A request like:

```text
http://shubhamgour.com/api
```

goes through:

```text
Gateway
  -> HTTPRoute
  -> /api rule matches
  -> backend-service
  -> backend pods
```

A request like:

```text
http://shubhamgour.com/
```

goes through:

```text
Gateway
  -> HTTPRoute
  -> / rule matches
  -> frontend-service
  -> frontend pods
```

This is the core idea of Gateway API path-based routing.

---

## 33. Make the Frontend and Backend Responses Different

To verify routing clearly, we want different output from each app.

### Frontend Deployment

Update `frontend-deployment.yaml`:

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
          image: nginx:alpine
          command: ["/bin/sh"]
          args:
            - -c
            - |
              echo 'FRONTEND APPLICATION' > /usr/share/nginx/html/index.html
              nginx -g 'daemon off;'
          ports:
            - containerPort: 80
```

Apply:

```bash
kubectl apply -f frontend-deployment.yaml
```

### Backend Deployment

Update `backend-deployment.yaml`:

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
          image: nginx:alpine

          command: ["/bin/sh"]

          args:
            - -c
            - |
              cat > /etc/nginx/conf.d/default.conf <<'EOF'
              server {
                  listen 80;

                  location = /api {
                      default_type text/plain;
                      return 200 "BACKEND APPLICATION\n";
                  }

                  location / {
                      root /usr/share/nginx/html;
                      index index.html;
                  }
              }
              EOF

              echo 'BACKEND APPLICATION' > /usr/share/nginx/html/index.html

              nginx -g 'daemon off;'

          ports:
            - containerPort: 80

```

```
          args: # Provides arguments to the shell command.
            - -c # Tells the shell to execute the following script.
            - | # Starts a multi-line shell script.
              cat > /etc/nginx/conf.d/default.conf <<'EOF' # Creates the NGINX configuration file.
              server { # Starts the NGINX server configuration.
                  listen 80; # Makes NGINX listen on port 80.
                  location = /api { # Handles requests exactly matching /api.
                      default_type text/plain; # Sets the response type to plain text.
                      return 200 "BACKEND APPLICATION\n"; # Returns HTTP 200 with the backend message.
                  } # Ends the /api location.
                  location / { # Handles other requests starting with /.
                      root /usr/share/nginx/html; # Sets the directory for NGINX web files.
                      index index.html; # Uses index.html as the default page.
                  } # Ends the root location.
              } # Ends the NGINX server configuration.
              EOF # Marks the end of the NGINX configuration.
              echo 'BACKEND APPLICATION' > /usr/share/nginx/html/index.html # Creates the default page with the backend message.
              nginx -g 'daemon off;' # Starts NGINX and keeps the container running.
```


Apply:

```bash
kubectl apply -f backend-deployment.yaml
```

Now the apps return different responses so we can clearly see which route is working.

---

## 34. Check the Gateway Address

Check the Gateway:

```bash
kubectl get gateway
```

Look at the `ADDRESS` column.

If no address is assigned, start Minikube tunnel again:

```bash
minikube tunnel
```

Then check again:

```bash
kubectl get gateway
```

---

## 35. Configure the Hostname

We want `shubhamgour.com` to point to our local Gateway.

Add the entry to `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

```bash
127.0.0.1 shubhamgour.com
```

Verify:

```bash
cat /etc/hosts
```

---

## 36. Configure the Gateway Listener

Update `gateway.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      hostname: shubhamgour.com
```

Apply:

```bash
kubectl apply -f gateway.yaml
```

Check:

```bash
kubectl describe gateway eg
```

---

## 37. Configure the HTTPRoute for the Hostname

Update `httproute.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: application-route
spec:
  parentRefs:
    - name: eg
  hostnames:
    - shubhamgour.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: backend-service
          port: 80
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: frontend-service
          port: 80
```

Apply:

```bash
kubectl apply -f httproute.yaml
```

Check:

```bash
kubectl describe httproute application-route
```

---

## 38. Test the Frontend Route

```bash
curl -v http://shubhamgour.com/
```

Expected result: front-end content.

This proves that:

```text
http://shubhamgour.com/ -> frontend-service
```

---

## 39. Test the Backend Route

```bash
curl -v http://shubhamgour.com/api
```

Expected result: backend content.

This proves that:

```text
http://shubhamgour.com/api -> backend-service
```

---

## 40. What We Proved With Gateway API

Gateway API allows us to describe traffic routing in a clean and portable way:

- Gateway receives the traffic
- HTTPRoute inspects the request
- HTTPRoute decides where to send it
- backendRefs identifies the target service

This is cleaner than attaching controller-specific instructions to an ingress object.

---

## 41. Key Difference: Ingress Annotations vs Gateway API

### Ingress + Annotation

- uses a controller-specific extra instruction
- may not work on another controller
- often used for rewrite or advanced behavior

### Gateway API

- uses standard Kubernetes objects
- follows a portable API model
- separates Gateway definition from request routing logic

---

## 42. Final Summary

Gateway API is a Kubernetes-native way to manage traffic entering the cluster.

The major resources are:

- GatewayClass: who manages the Gateway
- Gateway: where traffic enters
- HTTPRoute: where requests are routed

Using Gateway API, we can define:

- host-based routing
- path-based routing
- service selection
- clear and portable configuration

This is one of the main reasons Gateway API is becoming the modern standard for Kubernetes networking.

---

## 📝 Additional notes

- **Why this matters now:** the community Ingress NGINX controller used in the first half of this module was [retired on March 24, 2026](https://kubernetes.io/blog/2026/01/29/ingress-nginx-statement/). The project recommends the Gateway API, and [Ingress2Gateway](https://kubernetes.io/blog/2026/03/20/ingress2gateway-1-0-release/) can help convert existing Ingress resources.
- **The API isn't built into the cluster:** you install the Gateway API CRDs and a controller, such as Envoy Gateway in this demo.
- **Routing across namespaces:** a route can only reference a backend in another namespace if that namespace allows it with a `ReferenceGrant`.
- **Debug with status:** when a route doesn't work, check the conditions in `kubectl describe httproute <name>`. They usually explain why.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
