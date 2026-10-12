# Kubernetes Horizontal Pod Autoscaler (HPA)

## 1. Introduction

Horizontal Pod Autoscaler (HPA) is a Kubernetes feature that automatically changes the number of Pods in a Deployment based on resource usage such as CPU or memory.

This is useful when an application receives variable traffic. Instead of manually scaling the application, Kubernetes can scale it automatically based on metrics.

In simple words:

- traffic increases -> more Pods are created
- traffic decreases -> extra Pods are removed
- the goal is to keep application performance stable without overprovisioning

---

## 2. Why Do We Need HPA?

Imagine a web application running with only 1 Pod.

At low demand, 1 Pod is enough. But when traffic becomes heavy:

- response time increases
- CPU usage rises
- the app may become slow or unstable

Manually adding more Pods every time traffic changes is not scalable. HPA solves this automatically.

### Real-world analogy

Think of a restaurant:

- few customers = one chef is enough
- many customers = more chefs are needed
- HPA acts like a smart manager who adds or removes workers based on demand

---

## 3. What HPA Does

HPA watches metrics and adjusts the replica count of a workload.

It does not change the CPU or memory assigned to each Pod. Instead, it changes how many Pods are running.

### Example

If:

- current CPU usage is 80%
- target CPU is 50%

then HPA decides that more replicas are needed.

If:

- CPU usage falls below the target

then HPA can reduce the number of replicas.

---

## 4. Prerequisites

Before using HPA, the cluster must have metrics available.

### Install and enable Metrics Server

```bash
minikube start --profile hpa-demo --driver=docker
minikube --profile hpa-demo addons enable metrics-server
kubectl config use-context hpa-demo
kubectl get nodes
kubectl top nodes
```

### Why is this important?

HPA needs metrics such as CPU usage to make decisions. Metrics Server collects and exposes this data to Kubernetes.

If `kubectl top nodes` does not show metrics, wait a little and try again.

---

## 5. Application Deployment YAML

Create a file named `hpa-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
        - name: php-apache
          image: registry.k8s.io/hpa-example
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 200m
            limits:
              cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  selector:
    app: php-apache
  ports:
    - port: 80
      targetPort: 80
```

### Explanation

- `replicas: 1` means only one Pod is created initially
- `selector` links the Deployment with the Pods it manages
- `requests.cpu: 200m` tells Kubernetes the Pod normally needs 200 millicores
- `limits.cpu: 500m` sets the maximum CPU limit
- the `Service` gives a stable endpoint for traffic generation

### Deploy the application

```bash
kubectl apply -f hpa-app.yaml
kubectl get deployment php-apache
kubectl get pods
kubectl get service php-apache
```

---

## 6. HPA YAML

Create a file named `hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

### Explanation

- `scaleTargetRef` tells HPA which workload to monitor and scale
- `minReplicas: 1` ensures at least one Pod is always running
- `maxReplicas: 5` prevents scaling beyond five Pods
- `averageUtilization: 50` means the target CPU usage is 50% of the requested CPU

### Apply HPA

```bash
kubectl apply -f hpa.yaml
kubectl get hpa
kubectl describe hpa php-apache-hpa
```

---

## 7. How HPA Calculates Scaling

HPA works on CPU utilization.

If the CPU request is `200m`, then 50% utilization means roughly:

```text
50% of 200m = 100m CPU usage
```

When the actual CPU usage rises above this target, HPA increases replicas. When it falls below, it reduces replicas.

This is why CPU requests matter in Kubernetes. HPA calculates utilization using the configured request.

---

## 8. Stress / Load Command Used for Testing

The following command is the workload generator used in the demo. It continuously sends requests to the application to increase CPU usage and trigger HPA.

```bash
kubectl run -i --tty load-generator \
  --rm \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c 'while sleep 0.01; do wget -q -O- http://php-apache >/dev/null; done'
```

### What does this command do?

- creates a temporary Pod named `load-generator`
- uses `busybox:1.36` as the base image
- runs a shell loop repeatedly
- each loop sends an HTTP request to `http://php-apache`
- this increases application traffic and CPU usage
- HPA observes the rising CPU and scales the Deployment automatically

This is effectively a stress-like traffic generator because it keeps the app busy with continuous requests.

### Optional direct Linux stress command

If you want a real CPU stress test on a Linux machine or in a container, you can also use:

```bash
stress --cpu 2 --io 1 --vm 1 --vm-bytes 128M --timeout 120s
```

### Explanation

- `--cpu 2` runs 2 CPU workers
- `--io 1` runs 1 I/O worker
- `--vm 1` creates 1 virtual memory worker
- `--vm-bytes 128M` allocates memory for VM stress
- `--timeout 120s` stops the stress test after 120 seconds

This type of command generates higher CPU and memory load, which is useful for testing autoscaling behavior.

---

## 9. Observe Autoscaling in Action

Open a terminal and run the load generator:

```bash
kubectl run -i --tty load-generator \
  --rm \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c 'while sleep 0.01; do wget -q -O- http://php-apache >/dev/null; done'
```

Now watch HPA:

```bash
kubectl get hpa php-apache-hpa --watch
```

And watch the Deployment:

```bash
kubectl get deployment php-apache --watch
```

You can also view resource usage:

```bash
kubectl top pods
```

### Expected behavior

- CPU utilization rises above 50%
- HPA calculates the required replica count
- Deployment creates more Pods
- the application scales horizontally

---

## 10. Scale-Down Behavior

Once the traffic stops, CPU usage will fall.

Stop the traffic generator using `Ctrl + C` in the load-generator terminal.

Then watch:

```bash
kubectl get hpa php-apache-hpa --watch
kubectl get deployment php-apache --watch
```

### Important note

Kubernetes may not scale down immediately. There is a default stabilization period for scale-down, so it can take some time before the Pod count moves back toward the minimum.

---

## 11. Key Points to Remember

- HPA scales the number of Pods, not the CPU/memory inside a single Pod
- HPA uses metrics such as CPU utilization and memory usage
- Metrics Server must be enabled for HPA to work properly
- `requests.cpu` is important because HPA calculates utilization against it
- `minReplicas` and `maxReplicas` define scaling boundaries

---

## 12. Summary

The Horizontal Pod Autoscaler helps Kubernetes automatically scale workloads when demand changes.

It is useful for:

- handling sudden increases in traffic
- maintaining application performance
- reducing manual intervention
- properly using cloud resources without overprovisioning

### Final takeaway

HPA watches resource metrics and adjusts the desired number of replicas in a Deployment. When CPU usage rises above the selected target, it adds more Pods. When usage drops, it reduces Pods again.

This is one of the most important automation features in Kubernetes.

---

## Happy Learning!

---

## Connect with Shubham Gour
- YouTube: https://youtube.com/shubhamgourtech
- LinkedIn: https://www.linkedin.com/in/theshubhamgour/
