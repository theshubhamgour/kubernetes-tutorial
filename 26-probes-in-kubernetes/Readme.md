# Kubernetes Probes

This tutorial introduces Kubernetes Probes and explains the difference between `startupProbe`, `readinessProbe`, and `livenessProbe`.

It focuses on when each probe is used, how the kubelet evaluates them, and how they affect Pod behavior during startup, traffic routing, and container restarts.

---

## 1. Scope

This lesson covers:

- what a Probe is
- why Kubernetes needs health checks
- the difference between Startup, Readiness, and Liveness
- a practical example using BusyBox
- how to watch Pod behavior when the app transitions through different states

---

## 2. Problem Statement

A Pod may look like it is `Running`, but that does not always mean the application is ready for user traffic.

An application can be:

- still starting up
- running but not ready to receive requests
- alive but stuck and no longer making progress
- healthy initially and then become unhealthy later

Kubernetes needs a way to understand the real health of the application. That is where Probes come in.

A Probe is a diagnostic check performed periodically by the kubelet against a container. Based on the result, Kubernetes can:

- restart an unhealthy container
- stop sending traffic to a Pod that is not ready
- wait before allowing liveness and readiness checks to begin

---

## 3. Three Probes

Kubernetes uses three main health checks:

```text
Startup
  "Have you finished starting?"

Readiness
  "Can you receive traffic?"

Liveness
  "Are you still functioning?"
```

### Startup Probe

The Startup Probe answers: "Has the application finished starting?"

This is useful when an application takes time to initialize. During startup, Kubernetes should not treat the app as broken just because it is not ready yet.

When a Startup Probe is configured, Kubernetes does not run the liveness and readiness checks until startup succeeds.

### Readiness Probe

The Readiness Probe answers: "Is the application ready to receive traffic?"

This is different from a restart check. If the application is running but not ready, we do not want to restart it; we want Kubernetes to stop sending traffic to it.

A failed Readiness Probe marks the Pod as not ready. Matching Services will stop sending regular traffic to that Pod.

### Liveness Probe

The Liveness Probe answers: "Is the application still functioning?"

This is used when the application is alive but stuck, deadlocked, or no longer making progress. In this case, Kubernetes should restart the container.

---

## 4. Example: Startup, Readiness and Liveness Together

A simple way to understand all three is to simulate an app with different phases:

- it starts slowly
- it becomes ready later
- it remains healthy for a while
- then it fails its health check and should be restarted

We will use a BusyBox Pod and a tiny HTTP server.

---

## 5. Demo YAML

Create a file named `probes-demo.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: probes-demo
  labels:
    app: probes-demo
spec:
  containers:
    - name: app
      image: busybox:1.36.1
      command:
        - /bin/sh
        - -c
        - |
          mkdir -p /www
          rm -f /www/startup
          rm -f /www/ready
          echo "OK" > /www/healthz
          busybox httpd -f -p 8080 -h /www &

          sleep 10
          echo "STARTED" > /www/startup

          sleep 10
          echo "READY" > /www/ready

          sleep 30
          rm -f /www/healthz
          wait

      ports:
        - containerPort: 8080

      startupProbe:
        httpGet:
          path: /startup
          port: 8080
        periodSeconds: 2
        failureThreshold: 15

      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        periodSeconds: 2
        failureThreshold: 1

      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        periodSeconds: 2
        failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: probes-service
spec:
  selector:
    app: probes-demo
  ports:
    - port: 8080
      targetPort: 8080
```

---

## 6. What the Script Is Doing

The script simulates several application states.

### Startup phase

```bash
rm -f /www/startup
```

At the beginning, the startup endpoint does not exist.

```bash
sleep 10
echo "STARTED" > /www/startup
```

After 10 seconds, the app creates `/startup`. This means the app has finished starting.

### Readiness phase

```bash
rm -f /www/ready
```

The app is not ready at first.

```bash
sleep 10
echo "READY" > /www/ready
```

After another 10 seconds, the app is ready to receive traffic.

### Liveness phase

```bash
echo "OK" > /www/healthz
```

The app begins in a healthy state.

```bash
sleep 30
rm -f /www/healthz
```

After 30 seconds, the health endpoint is removed. This simulates the app becoming unhealthy.

The BusyBox HTTP server is started with:

```bash
busybox httpd -f -p 8080 -h /www &
```

This exposes the files under `/www` on port `8080`.

For HTTP probes, kubelet sends an HTTP GET request to the Pod IP and port. A response in the `200-399` range is considered a success.

---

## 7. Understanding the YAML

### `apiVersion`

```yaml
apiVersion: v1
```

This tells Kubernetes which API version is being used. For a basic Pod, we use the core API version `v1`.

### `kind`

```yaml
kind: Pod
```

This tells Kubernetes that the resource is a `Pod`.

Later in the same file, the second resource is a `Service`:

```yaml
kind: Service
```

### `metadata`

```yaml
metadata:
  name: probes-demo
  labels:
    app: probes-demo
```

Metadata gives the resource identity and labels.

The label `app: probes-demo` is important because the Service will later use it as a selector.

### `spec`

```yaml
spec:
```

The `spec` describes what we want Kubernetes to create and how it should behave.

### `containers`

```yaml
containers:
  - name: app
    image: busybox:1.36.1
```

This creates a container named `app` using the BusyBox image.

### `command`

The `command` overrides the default container behavior and runs a shell script to simulate the application lifecycle.

This script intentionally creates different states to help us see what each probe does.

### `ports`

```yaml
ports:
  - containerPort: 8080
```

This declares that the application listens on port `8080`.

---

## 8. Startup Probe

```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  periodSeconds: 2
  failureThreshold: 15
```

The Startup Probe checks whether the application has finished starting.

- `httpGet` means Kubernetes will perform an HTTP GET request
- `path: /startup` is the endpoint to check
- `port: 8080` is the port where the application is listening
- `periodSeconds: 2` means the check runs every 2 seconds
- `failureThreshold: 15` means the probe can fail 15 times before it is considered failed

This gives the application enough time to initialize.

Once the Startup Probe succeeds, Kubernetes starts running readiness and liveness checks.

---

## 9. Readiness Probe

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 2
  failureThreshold: 1
```

The Readiness Probe tells Kubernetes whether the application is ready to receive traffic.

During the initial phase, `/ready` does not exist, so readiness fails. The Pod stays running, but it is not considered ready.

After the application creates `/ready`, the readiness check succeeds and Kubernetes can send traffic to the Pod.

### Key idea

```text
Application running
   ↓
Readiness fails
   ↓
Pod is not ready
   ↓
No normal traffic sent to it
```

---

## 10. Liveness Probe

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  periodSeconds: 2
  failureThreshold: 3
```

The Liveness Probe tells Kubernetes whether the application is still alive and healthy.

Initially `/healthz` exists, so the app is considered healthy. Later, the script removes the endpoint to simulate failure. After 3 failed checks, the container is restarted.

### Key idea

```text
Application running
   ↓
Health check fails
   ↓
Kubernetes restarts the container
```

---

## 11. The `---` Separator

In YAML, `---` separates multiple documents in the same file.

So this file contains two resources:

1. a Pod
2. a Service

---

## 12. Service and Selector

```yaml
apiVersion: v1
kind: Service
metadata:
  name: probes-service
spec:
  selector:
    app: probes-demo
  ports:
    - port: 8080
      targetPort: 8080
```

This Service selects Pods with the label:

```yaml
app: probes-demo
```

The Service sends traffic only to matching Pods that are ready.

### `port` vs `targetPort`

- `port` is the port exposed by the Service
- `targetPort` is the actual port on the Pod/container

In this example, both are `8080`.

```text
Client
  ↓
Service :8080
  ↓
Pod :8080
  ↓
Application
```

---

## 13. Apply the Demo

Run the following command:

```bash
kubectl apply -f probes-demo.yaml
```

Then watch the Pod:

```bash
kubectl get pod probes-demo -w
```

This will show the lifecycle:

### Phase 1: Startup

- application starts
- `/startup` does not exist yet
- startup probe fails repeatedly
- after the delay, `/startup` is created
- startup probe succeeds

### Phase 2: Readiness

- `/ready` does not exist yet
- readiness probe fails
- Pod remains running but not ready
- after the delay, `/ready` is created
- readiness succeeds
- Pod becomes ready

### Phase 3: Liveness

- `/healthz` is removed intentionally
- liveness probe starts failing
- after three failures, the container restarts

---

## 14. Verify Restart

```bash
kubectl get pod probes-demo
```

Look at the `RESTARTS` column. The container should show a restart count.

You can also inspect events:

```bash
kubectl describe pod probes-demo
```

The events will show the probe failures and container restart activity.

---

## 15. Final Recap

```text
Startup Probe
  "Have you finished starting?"

Readiness Probe
  "Can you receive traffic?"

Liveness Probe
  "Are you still functioning?"
```

### Summary:

- Startup Probe protects the application while it is still booting
- Readiness Probe controls whether traffic should be sent to a Pod
- Liveness Probe restarts the container when it becomes unhealthy

These three probes solve different problems, and together they give Kubernetes a clear picture of the container's health.

---

## 16. Cleanup

Delete the resources after the experiment:

```bash
kubectl delete -f probes-demo.yaml
```

---

## 17. Conclusion

Kubernetes health checks are essential for managing real-world application behavior. Without them, a Pod can look healthy even when it is still initializing, not ready for traffic, or stuck and no longer functioning correctly.

The right probe is chosen based on the question we need Kubernetes to answer:

- Startup: "Have you finished starting?"
- Readiness: "Can you receive traffic?"
- Liveness: "Are you still functioning?"

This is the foundation of safe and reliable application lifecycle management in Kubernetes.
