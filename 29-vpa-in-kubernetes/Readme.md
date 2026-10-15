# Kubernetes Vertical Pod Autoscaler (VPA)

This guide explains how the Kubernetes Vertical Pod Autoscaler (VPA) observes CPU and memory usage, recommends resource requests, and can apply updated requests to Pods. The hands-on example runs on a dedicated Minikube profile.

## 1. Introduction

The Vertical Pod Autoscaler (VPA) helps right-size container resource requests based on observed workload usage.

- **HPA** changes the number of Pods.
- **VPA** recommends or changes the CPU and memory requests assigned to Pods.

VPA is not installed in a standard Kubernetes cluster by default. This guide installs it in Minikube, deploys a small CPU-consuming application, and inspects VPA recommendations.

## 2. How VPA Works

VPA has three main components:

- **Recommender** observes resource usage and calculates recommendations.
- **Updater** determines whether running Pods should be updated.
- **Admission Controller** applies recommended resources to newly created Pods.

VPA recommendations take time to become useful because the Recommender needs to observe the workload. Exact recommendations depend on the application, the time it has been running, and the cluster.

### VPA update modes

- `Off`: calculates recommendations but does not change Pods.
- `Recreate`: can evict a Pod when its resources should change. A controller such as a Deployment creates a replacement, and the Admission Controller applies the recommended requests.

`Recreate` can disrupt an application. For production workloads, start by reviewing recommendations in `Off` mode and plan availability before enabling automatic updates.

## 3. Prerequisites

You will need:

- A supported operating system: macOS, Linux, or Windows.
- A container runtime supported by Minikube. This guide uses Docker.
- `kubectl` and Minikube installed and available on your `PATH`.
- Git and an internet connection.
- Enough resources for the cluster and demo workloads. For this example, allocate at least 4 CPUs and 6 GiB of memory to Docker or the VM that runs Docker.

Install Docker Desktop on macOS or Windows, or install and start Docker Engine on Linux. Follow the official [Docker installation instructions](https://docs.docker.com/engine/install/).

Install `kubectl` using the [official Kubernetes instructions](https://kubernetes.io/docs/tasks/tools/), and install Minikube using the [official Minikube start guide](https://minikube.sigs.k8s.io/docs/start/). Verify the tools before continuing:

```bash
docker version
kubectl version --client
minikube version
git --version
```

`docker version` should show both client and server information. If it cannot contact the Docker daemon, start Docker Desktop or the Docker service before starting Minikube.

## 4. Create and Prepare a Minikube Cluster

Use a dedicated profile named `vpa-demo` so this tutorial's settings and resources remain separate from other Minikube experiments.

### Start the cluster

```bash
minikube start \
  --profile=vpa-demo \
  --driver=docker \
  --cpus=4 \
  --memory=6g \
  --kubernetes-version=v1.36.0
```

What these options mean:

- `--profile=vpa-demo` creates or starts a cluster with its own named profile and context.
- `--driver=docker` runs the Minikube node in Docker. Docker must already be running.
- `--cpus=4` and `--memory=6g` allocate resources to the local Kubernetes node. Adjust these values if your machine has less capacity; make sure the host and Docker have enough resources available.
- `--kubernetes-version=v1.36.0` pins the cluster version for a repeatable demonstration. If that version is unavailable in your Minikube release, use a Kubernetes version supported by both Minikube and the VPA release you intend to install.

The first start can take several minutes while Minikube downloads the node image and configures Kubernetes. Minikube manages this cluster independently of any remote cluster configured in your kubeconfig.

### Select and verify the profile

Minikube normally selects the profile's context when it starts. Explicitly selecting it helps avoid applying demo resources to the wrong cluster:

```bash
kubectl config use-context vpa-demo
kubectl config current-context
```

The current context should be `vpa-demo`. Check that the node is ready:

```bash
kubectl get nodes
kubectl cluster-info
```

Wait for the node's `STATUS` to become `Ready` before proceeding.

### Enable Metrics Server

```bash
minikube --profile=vpa-demo addons enable metrics-server
```

Metrics Server provides recent CPU and memory usage metrics to the Kubernetes Metrics API. VPA uses usage observations when calculating recommendations. Give the add-on time to start, then verify that it is available:

```bash
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
```

If `kubectl top nodes` reports that metrics are not available yet, wait a short while and retry. Do not continue to evaluate VPA recommendations until metrics are being reported.

## 5. Install VPA

The Kubernetes autoscaler repository contains VPA's installation and teardown scripts. The following commands clone the repository into a new working directory and run the VPA setup script:

```bash
mkdir -p ~/k8s-vpa-demo
cd ~/k8s-vpa-demo
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```

The setup script installs VPA's Kubernetes resources, including its custom resource definition (CRD), permissions, and controller components. It may take a few minutes for the component images to download and the Pods to become ready.

### Verify the installation

Confirm that the VPA resource type has been registered:

```bash
kubectl get crd verticalpodautoscalers.autoscaling.k8s.io
```

Inspect VPA components in `kube-system`:

```bash
kubectl get deployments -n kube-system
kubectl get pods -n kube-system
```

Wait for the Recommender, Updater, and Admission Controller Pods installed by the script to be ready. Their exact Pod names can vary by VPA release. You can also inspect the startup events if a component does not become ready:

```bash
kubectl get events -n kube-system --sort-by=.lastTimestamp
```

Do not create a `VerticalPodAutoscaler` resource until its CRD exists and the VPA components are running.

> **Version compatibility:** The VPA setup script installs the version in the cloned autoscaler checkout. For repeatable or production environments, use a specific autoscaler release or commit that supports your Kubernetes version rather than relying on the repository's moving default branch.

## 6. Deploy the Sample Application

Create `vpa-app.yml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vpa-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vpa-demo
  template:
    metadata:
      labels:
        app: vpa-demo
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
      containers:
        - name: app
          image: registry.k8s.io/ubuntu-slim:0.14
          resources:
            requests:
              cpu: 100m
              memory: 50Mi
          command:
            - /bin/sh
          args:
            - "-c"
            - "while true; do timeout 0.5s yes >/dev/null; sleep 0.5s; done"
```

### Manifest explanation

- `replicas: 2` asks the Deployment to keep two application Pods running.
- The selector and Pod labels both use `app: vpa-demo`, connecting the Deployment to the Pods it manages.
- `runAsNonRoot` and `runAsUser` run the container as an unprivileged user.
- The initial requests are `100m` CPU (100 millicores) and `50Mi` memory (50 mebibytes).
- The command repeatedly generates CPU activity with short pauses so the Recommender has CPU usage to observe. This example does not deliberately create high memory usage, so a higher memory recommendation is not guaranteed.

Apply the Deployment and verify the Pods:

```bash
kubectl apply -f vpa-app.yml
kubectl rollout status deployment/vpa-demo
kubectl get pods -l app=vpa-demo
kubectl top pods -l app=vpa-demo
```

## 7. Configure VPA

Create `vpa-policy.yml`:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: vpa-demo
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: vpa-demo
  updatePolicy:
    updateMode: Recreate
  resourcePolicy:
    containerPolicies:
      - containerName: app
        minAllowed:
          cpu: 100m
          memory: 50Mi
        maxAllowed:
          cpu: "1"
          memory: 500Mi
        controlledResources:
          - cpu
          - memory
        controlledValues: RequestsOnly
```

### VPA manifest explanation

- `targetRef` identifies the Deployment whose Pods VPA should manage.
- `updateMode: Recreate` allows VPA to evict Pods when it decides resource requests should change. The Deployment replaces evicted Pods.
- `minAllowed` and `maxAllowed` bound the recommendations for this container: CPU from `100m` to `1` core and memory from `50Mi` to `500Mi`.
- `controlledResources` limits VPA management to CPU and memory.
- `controlledValues: RequestsOnly` means VPA controls requests, not limits.

Apply the VPA resource only after VPA installation has completed:

```bash
kubectl apply -f vpa-policy.yml
kubectl get vpa vpa-demo
kubectl get pods -l app=vpa-demo
```

## 8. Inspect Recommendations

Allow the application to run while VPA observes its resource usage. Then inspect the VPA resource:

```bash
kubectl describe vpa vpa-demo
kubectl get vpa vpa-demo -o yaml
```

Look in `status.recommendation`. VPA can report a target request along with lower and upper recommendation bounds for each container. These recommendations are based on observed usage and VPA's safety margins; they are not guaranteed to match a particular number or appear immediately.

If `status.recommendation` is empty:

1. Confirm Metrics Server is running and `kubectl top pods -l app=vpa-demo` returns usage.
2. Confirm the VPA Recommender Pod is ready.
3. Leave the application running longer, then inspect the VPA again.
4. Check VPA component and workload events for errors.

## 9. Observe Applied Resource Requests

With `Recreate` mode, VPA may evict Pods when it decides their requests should be updated. The Deployment should create replacement Pods. Watch them in one terminal:

```bash
kubectl get pods -l app=vpa-demo --watch
```

In another terminal, check the current Pods and their resource requests:

```bash
kubectl get pods -l app=vpa-demo
kubectl get pod <pod-name> -o yaml
```

In the Pod YAML, inspect `spec.containers[].resources.requests`. VPA applies recommendations when Pods are admitted; it does not necessarily rewrite the Deployment's original Pod template. Therefore, inspect a running Pod to see the resources actually assigned to it.

VPA might not recreate Pods immediately. It takes time to collect usage, and it only updates Pods when its policy and update decision indicate a change is appropriate.

## 10. Use Recommendation-Only Mode

To inspect recommendations without automatically evicting Pods, set the VPA update mode to `Off`:

```yaml
  updatePolicy:
    updateMode: Off
```

Save the change in `vpa-policy.yml` and apply it:

```bash
kubectl apply -f vpa-policy.yml
```

VPA will continue to calculate recommendations, but will not automatically update the workload's Pods. Review the recommendation and make resource changes through your normal deployment process.

## 11. VPA and HPA

| Autoscaler | What it changes | Typical use |
|------------|-----------------|-------------|
| HPA | Number of Pods | Add or remove replicas as workload demand changes |
| VPA | CPU and memory requests for Pods | Right-size resources based on observed usage |

Using HPA and VPA together requires care. For example, HPA CPU utilization is calculated relative to CPU requests, which VPA may change. Avoid letting both autoscalers independently react to the same resource metric without understanding how their decisions interact.

## 12. Cleanup

Delete the demo VPA resource and Deployment:

```bash
kubectl delete -f vpa-policy.yml
kubectl delete -f vpa-app.yml
```

To remove the VPA installation but keep the Minikube cluster, run the teardown script from the VPA checkout:

```bash
cd ~/k8s-vpa-demo/autoscaler/vertical-pod-autoscaler
./hack/vpa-down.sh
```

When you no longer need this tutorial's cluster, delete only the `vpa-demo` profile:

```bash
minikube delete --profile=vpa-demo
```

## 13. Summary

- HPA changes the number of Pods; VPA recommends or changes the resource requests assigned to Pods.
- Metrics Server supplies usage data used by VPA.
- VPA needs time to observe a workload before its recommendations become useful.
- `Off` is useful for reviewing recommendations without automatic Pod updates.
- `Recreate` can apply updated requests by evicting and replacing Pods, so consider application availability.
- Recommendations are workload- and environment-dependent; inspect the actual Pod requests to verify applied changes.

---

## Happy Learning!

---

## Connect with Shubham Gour
- YouTube: https://youtube.com/shubhamgourtech
- LinkedIn: https://www.linkedin.com/in/theshubhamgour/