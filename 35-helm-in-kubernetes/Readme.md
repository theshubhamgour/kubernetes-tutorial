# Helm Explained for Beginners

A practical guide to understanding Helm, charts, values, templates, releases and rollback workflows using Minikube.

This tutorial is based on the "Helm Explained for Beginners — Full Voice-Over Script (Minikube Hands-On)" walkthrough and turns it into a clean, reusable study guide.

---

## 1. Why Helm Exists

Before Helm, deploying an application on Kubernetes usually meant writing multiple YAML files:

- Deployment YAML
- Service YAML
- ConfigMap YAML
- Secret YAML
- maybe more for production, staging and dev

For a simple app, that is manageable. But in a real project, you may have many environments and many resources. The same app may be deployed with small differences:

- dev: 1 replica
- staging: 2 replicas
- production: 5 replicas

If you copy the same YAML files multiple times, you create a maintenance problem:

- you update the same values in many places
- a missed change can make environments inconsistent
- upgrading an image version becomes error-prone

Helm solves this by letting you define a chart once and then override values for each environment.

---

## 2. What Is Helm?

Helm is a package manager for Kubernetes.

Think of it like `apt`, `yum`, or `brew`, but for applications running on Kubernetes.

It helps you:

- package Kubernetes resources together
- customize configuration with values
- install or upgrade an application in one step
- manage versions and rollbacks

### Key Helm terms

- Chart: a package of Kubernetes manifests and configuration
- Release: a specific installation of a chart
- Repository: a place where charts are stored and shared
- Template: YAML with placeholders filled in from values

Important: Helm does not replace Kubernetes.

Kubernetes is the runtime that creates and manages Pods, Deployments and Services. Helm is the tool that helps you package and install those resources on Kubernetes.

---

## 3. Helm Core Concepts

### Chart

A Helm chart is simply a folder with a specific structure. It contains files that describe how to deploy an application.

The main pieces are:

- `Chart.yaml` — metadata for the chart
- `values.yaml` — default configuration values
- `templates/` — YAML templates for Kubernetes resources

### Values and templates

Values are inputs. Templates are parameterized YAML files.

Example in `values.yaml`:

```yaml
replicaCount: 2
image:
  repository: nginx
  tag: "1.27"
  pullPolicy: IfNotPresent
```

Example in a Deployment template:

```yaml
spec:
  replicas: {{ .Values.replicaCount }}
```

Helm replaces `{{ .Values.replicaCount }}` with the actual value from `values.yaml` before sending the final YAML to Kubernetes.

### Release

When you install a chart, Helm creates a release.

Example:

```bash
helm install my-nginx ./hello-app --namespace helm-demo --create-namespace
```

Here:

- `my-nginx` is the release name
- `./hello-app` is the chart path
- `helm-demo` is the namespace

### Repository

A chart repository is a central place where Helm charts can be stored and shared. A chart can be installed locally from a folder or fetched from a repository.

---

## 4. Prerequisites

We will use Minikube for a local Kubernetes cluster.

### Check Helm

```bash
helm version
```

If you get a version number, Helm is installed.

### Check Minikube

```bash
minikube version
minikube start
minikube status
```

You should see a running control plane and kubeconfig configured.

### Confirm the cluster

```bash
kubectl get nodes
kubectl config current-context
```

This verifies that `kubectl` and Helm are pointing to the same cluster. This is important because Helm installs to the cluster defined by your kubeconfig.

---

## 5. Create the Demo Chart

Start in a fresh directory:

```bash
mkdir helm-beginner-demo
cd helm-beginner-demo
```

Create the chart:

```bash
helm create hello-app
```

This generates a starter chart structure.

Then remove the default templates so you can build your own simple chart:

```bash
rm -rf hello-app/templates/*
```

Now your chart folder should look like this:

```text
hello-app/
├── Chart.yaml
├── charts/
├── templates/
├── values.yaml
```

---

## 6. Write the Chart Files

### `Chart.yaml`

```yaml
apiVersion: v2
name: hello-app
description: A simple Helm chart for deploying NGINX on Kubernetes
type: application
version: 0.1.0
appVersion: "1.27"
```

Explanation:

- `apiVersion: v2` — Helm chart format version
- `name` — chart name
- `description` — human readable description
- `type` — application type
- `version` — chart package version
- `appVersion` — the app version inside the package (NGINX 1.27)

Note:

- `version` refers to the chart package version.
- `appVersion` refers to the image version inside the chart.

### `values.yaml`

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.27"
  pullPolicy: IfNotPresent

containerPort: 80

service:
  type: ClusterIP
  port: 80
```

Important notes:

- indentation must use spaces, not tabs
- `tag` is quoted to avoid YAML interpreting `1.27` as a float-like value
- `port: 80` and `containerPort: 80` are defaults that can be overridden later

---

## 7. Deployment Template

Create `hello-app/templates/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
  labels:
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: nginx
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.containerPort }}
```

### Explanation

- `{{ .Release.Name }}` uses the Helm release name to generate a unique resource name
- `replicas` comes from `values.yaml`
- `image` is built using repository + tag values
- `containerPort` matches the port NGINX listens on

This template generates a standard Kubernetes Deployment object.

---

## 8. Service Template

Create `hello-app/templates/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-service
  labels:
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.containerPort }}
      protocol: TCP
```

### Explanation

The Service selects Pods using the same label as the Deployment.

That means:

- the Deployment creates Pods with `app.kubernetes.io/instance: my-nginx`
- the Service selects those Pods by the same label
- incoming traffic on the Service port is routed to the Pod's `targetPort`

This keeps the app accessible inside the cluster with a stable endpoint.

---

## 9. Check the Chart Before Installing

### `helm lint`

```bash
helm lint ./hello-app
```

Example result:

```text
==> Linting ./hello-app
[INFO] Chart.yaml: icon is recommended
1 chart(s) linted, 0 chart(s) failed
```

This catches common issues such as malformed YAML or invalid template syntax.

### `helm template`

```bash
helm template my-nginx ./hello-app
```

This renders the chart locally without installing it to the cluster.

You will see output like:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx-deployment
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: nginx
          image: "nginx:1.27"
```

This is a safe way to confirm the final YAML before deploying.

---

## 10. Install the Chart

Install the chart into a namespace:

```bash
helm install my-nginx ./hello-app --namespace helm-demo --create-namespace
```

### What this does

- `helm install` tells Helm to install the chart
- `my-nginx` is the release name
- `./hello-app` is the chart location
- `--namespace helm-demo` installs it in a dedicated namespace
- `--create-namespace` creates the namespace automatically if missing

Expected output:

```text
NAME: my-nginx
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 1
```

### List releases

```bash
helm list --namespace helm-demo
```

You should see your release with `status: deployed` and revision `1`.

---

## 11. Verify the Deployment in Kubernetes

```bash
kubectl get deployments,pods,services --namespace helm-demo
```

Example result:

```text
NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-nginx-deployment   2/2     2            2           40s

NAME                                       READY   STATUS    RESTARTS   AGE
pod/my-nginx-deployment-6d8f7c9b5d-4kx2p   1/1     Running   0          40s
pod/my-nginx-deployment-6d8f7c9b5d-q9wzt   1/1     Running   0          40s

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/my-nginx-service   ClusterIP   10.105.32.18    <none>        80/TCP    40s
```

Check rollout status:

```bash
kubectl rollout status deployment/my-nginx-deployment --namespace helm-demo
```

Expected result:

```text
deployment "my-nginx-deployment" successfully rolled out
```

---

## 12. Access the App

The Service type is `ClusterIP`, which means the app is accessible only inside the cluster by default.

For local testing, use port forwarding:

```bash
kubectl port-forward service/my-nginx-service 8080:80 --namespace helm-demo
```

This creates a temporary tunnel from your machine to the Service:

```text
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

Open:

```text
http://localhost:8080
```

You should see the default NGINX welcome page.

---

## 13. Upgrade the Release

To scale from 2 replicas to 3:

```bash
helm upgrade my-nginx ./hello-app --namespace helm-demo --set replicaCount=3
```

This changes the value without editing the template itself.

Alternatively, modify `values.yaml` and run:

```bash
helm upgrade my-nginx ./hello-app --namespace helm-demo
```

Check the updated resource:

```bash
kubectl get pods --namespace helm-demo
```

The Deployment should now show 3 Pods.

### Helm revision tracking

Each upgrade creates a new release revision:

```bash
helm history my-nginx --namespace helm-demo
```

Example:

```text
REVISION  UPDATED                   STATUS     CHART        APP VERSION
1        ...                      deployed   hello-app   1.27
2        ...                      deployed   hello-app   1.27
```

This is one of Helm's biggest advantages: you can trace changes over time.

---

## 14. Roll Back the Release

If something goes wrong, you can revert to an earlier revision.

For example, to go back to revision 1:

```bash
helm rollback my-nginx 1 --namespace helm-demo
```

This reverts the deployment to the state captured in that revision.

You can verify it with:

```bash
helm list --namespace helm-demo
kubectl get pods --namespace helm-demo
```

This is the same idea behind safe application updates: deploy, verify, and roll back if needed.

---

## 15. Summary

Helm makes Kubernetes easier to manage by packaging resources into charts.

The core workflow is simple:

1. Write a Helm chart
2. Define default values in `values.yaml`
3. Use templates to generate Kubernetes YAML
4. Install the chart with Helm
5. Upgrade it with changed values
6. Roll back when needed

### The three important ideas to remember

- Chart = the package
- Release = the installed instance
- Repository = the place charts are stored

### The most important chart files

- `Chart.yaml` — chart metadata
- `values.yaml` — defaults and configuration
- `templates/*.yaml` — Kubernetes manifests with placeholders

### The most important Helm commands

```bash
helm lint ./hello-app
helm template my-nginx ./hello-app
helm install my-nginx ./hello-app --namespace helm-demo --create-namespace
helm upgrade my-nginx ./hello-app --namespace helm-demo --set replicaCount=3
helm history my-nginx --namespace helm-demo
helm rollback my-nginx 1 --namespace helm-demo
helm uninstall my-nginx --namespace helm-demo
```

---

## 16. Final Thoughts

Helm does not replace Kubernetes. It makes Kubernetes operations much easier by turning repetitive YAML into reusable packages and values-driven templates.

The big win is this:

- one chart
- many environments
- different values
- no copy-paste chaos

That is the heart of Helm.

If you follow along on Minikube and build the chart step by step, the concepts become much easier to understand and remember.
