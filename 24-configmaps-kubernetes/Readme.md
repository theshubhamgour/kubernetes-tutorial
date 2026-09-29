# Kubernetes ConfigMap

This tutorial introduces Kubernetes ConfigMap and explains how configuration values can be separated from application code and injected into Pods.

## 1. Scope

This lesson focuses on:

- what a ConfigMap is
- why it is useful
- how to create a ConfigMap
- how to use it as environment variables
- how to mount it as a file
- how updates behave in different usage patterns

---

## 2. Problem Statement

Applications often depend on values such as:

- `APP_ENV=development`
- `DATABASE_HOST=mysql`
- `LOG_LEVEL=info`
- `APP_PORT=8080`

These values are configuration data, not part of the application itself. They may differ between environments without changing the application logic.

Without a ConfigMap:

- the same image may need to be rebuilt for different environments
- configuration is tightly coupled to the application image

With a ConfigMap:

- the image stays the same
- configuration is injected separately
- the same application can run in multiple environments with different configs

---

## 3. What is a ConfigMap?

A ConfigMap is a Kubernetes object used to store non-sensitive configuration data in key-value format.

Example:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: development
  LOG_LEVEL: info
  APP_NAME: shopping-api
```

Key points:

- ConfigMap stores configuration, not application data
- It holds non-confidential settings
- It is not intended for passwords, tokens, or private keys
- Sensitive data should be stored using a Kubernetes Secret or an external secret manager

---

## 4. ConfigMap vs Secret

| Object | Used for |
| --- | --- |
| ConfigMap | non-sensitive configuration |
| Secret | passwords, tokens, certificates, private keys |

A ConfigMap is the correct choice for values like environment names, ports, feature flags, API URLs, and log levels.

---

## 5. Real-World Analogy

Think of a TV:

- the TV itself is the application
- brightness, volume, language, and input are configuration settings
- you change those settings without rebuilding the entire TV

The same idea applies to an application running in Kubernetes.

---

## 6. First ConfigMap Example

Create a file named `app-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: development
  LOG_LEVEL: info
  APP_NAME: shopping-api
```

Apply it:

```bash
kubectl apply -f app-config.yaml
```

Check it:

```bash
kubectl get configmap
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
```

The `DATA` column shows the number of key-value pairs in the ConfigMap.

ConfigMaps are namespaced. A ConfigMap named `app-config` in one namespace is different from a ConfigMap with the same name in another namespace.

---

## 7. Using ConfigMap as Environment Variables

One common use of ConfigMap is to inject values into a container as environment variables.

### Example Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-env-pod
spec:
  containers:
    - name: app
      image: busybox
      command:
        - sh
        - -c
        - sleep 3600
      env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_ENV
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: LOG_LEVEL
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_NAME
```

### Explanation

- `env` defines environment variables inside the container
- `valueFrom` tells Kubernetes to fetch the value from another object
- `configMapKeyRef` reads a specific key from a ConfigMap

For example:

```yaml
configMapKeyRef:
  name: app-config
  key: APP_ENV
```

means:

- look up the ConfigMap `app-config`
- read the key `APP_ENV`
- set that value in the container environment

### Verify the values

```bash
kubectl exec configmap-env-pod -- printenv | grep -E 'APP_ENV|LOG_LEVEL|APP_NAME'
```

Expected output:

```bash
APP_ENV=development
LOG_LEVEL=info
APP_NAME=shopping-api
```

---

## 8. Using envFrom to Import All Keys

Instead of selecting each value one by one, you can import all keys from a ConfigMap with `envFrom`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: envfrom-demo
spec:
  containers:
    - name: app
      image: busybox
      command:
        - sh
        - -c
        - sleep 3600
      envFrom:
        - configMapRef:
            name: app-config
```

This imports all key-value pairs from the ConfigMap as container environment variables.

### Difference between the two patterns

- `configMapKeyRef` → select one specific key
- `envFrom` → load all keys from the ConfigMap

---

## 9. Using ConfigMap as a Mounted File

Some applications do not read values from environment variables. Instead, they expect configuration files such as:

- `app.properties`
- `application.yaml`
- `nginx.conf`
- `logging.conf`

In those situations, a ConfigMap can be mounted as a volume.

### Example ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-file-config
data:
  app.properties: |
    app.name=shopping-api
    app.environment=development
    log.level=info
```

### Pod using it as a volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-pod
spec:
  containers:
    - name: app
      image: busybox
      command:
        - sh
        - -c
        - sleep 3600
      volumeMounts:
        - name: config-volume
          mountPath: /etc/myapp
          readOnly: true
  volumes:
    - name: config-volume
      configMap:
        name: app-file-config
```

### What happens here?

- the `volumes` section defines a volume based on the ConfigMap
- the `volumeMounts` section mounts it inside the container
- the key `app.properties` appears as a file at `/etc/myapp/app.properties`

### Verify it

```bash
kubectl exec configmap-volume-pod -- ls -la /etc/myapp
kubectl exec configmap-volume-pod -- cat /etc/myapp/app.properties
```

Expected output:

```text
app.name=shopping-api
app.environment=development
log.level=info
```

---

## 10. ConfigMap Can Contain Multiple Files

A single ConfigMap can store multiple keys, and each key can be mounted as a separate file.

```yaml
data:
  app.properties: |
    ...
  logging.conf: |
    ...
  feature-flags.conf: |
    ...
```

When mounted under `/etc/myapp`, the result can be:

```text
/etc/myapp/app.properties
/etc/myapp/logging.conf
/etc/myapp/feature-flags.conf
```

This is very useful for applications that rely on configuration files rather than environment variables.

---

## 11. How Updates Behave

This part is very important.

### A. ConfigMap as environment variables

If the ConfigMap changes after the Pod starts, the existing environment variables inside the running container do not automatically update.

Example:

- ConfigMap contains `APP_ENV=production`
- running Pod still has `APP_ENV=development`
- the process environment was set when the container started

The old environment stays in memory until the Pod is recreated or restarted.

So the safest approach is:

```bash
kubectl delete pod configmap-env-pod
kubectl apply -f configmap-env-pod.yaml
```

### B. ConfigMap as mounted volume

When a ConfigMap is mounted as a file, Kubernetes updates the file in the mounted directory as the ConfigMap changes.

This means:

- the mounted file can reflect the updated value
- but the application may still be using old values in memory

The application may need to reload the config or restart to pick up the new values.

Important difference:

```text
ConfigMap updated
   ↓
Mounted file updated
   ↓
Application may still use old in-memory configuration
```

---

## 12. Benefits of ConfigMap

ConfigMap helps separate configuration from the application image.

Benefits include:

- same image can be reused across environments
- configuration can change without rebuilding the image
- easier rollout across dev, test, and production
- cleaner separation of code and operational settings

Example:

- same app image
- development uses `APP_ENV=development`
- production uses `APP_ENV=production`

---

## 13. Create a ConfigMap Imperatively

You can also create a ConfigMap directly from the command line.

```bash
kubectl create configmap example-config \
  --from-literal=APP_ENV=development \
  --from-literal=LOG_LEVEL=info
```

You can also create it from a file:

```bash
kubectl create configmap example-config --from-file=app.properties
```

This is useful for quick experiments and demos.

---

## 14. ConfigMap Size Limit

ConfigMaps are not meant for large data storage.

Kubernetes limits ConfigMap data to a practical size around 1 MiB.

This makes them suitable for configuration, not for storing large datasets or application databases.

---

## 15. Immutable ConfigMap

A ConfigMap can also be marked as immutable.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
data:
  APP_ENV: production
immutable: true
```

Once marked immutable:

- the ConfigMap contents cannot be changed
- if a new configuration is required, a new ConfigMap must be created

This is useful when configuration should not be modified accidentally.

---

## 16. Common Commands

```bash
kubectl apply -f app-config.yaml
kubectl get configmap
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
kubectl exec configmap-env-pod -- printenv | grep APP_ENV
kubectl exec configmap-volume-pod -- cat /etc/myapp/app.properties
kubectl edit configmap app-config
```

---

## 17. Quick Summary

- ConfigMap stores non-sensitive configuration data
- It is a Kubernetes object, not a storage volume
- It can be used as:
  - environment variables
  - mounted configuration files
- `configMapKeyRef` selects a specific key
- `envFrom` loads all keys from the ConfigMap
- Environment variable changes do not update an already-running process automatically
- Mounted file updates can appear quickly, but the app itself may still need a reload
- Use Secret for sensitive values

---

## 18. Final Note

ConfigMap is one of the most important resource types in Kubernetes because it keeps configuration separate from application code. This makes deployments more flexible, portable, and easier to manage across different environments.
