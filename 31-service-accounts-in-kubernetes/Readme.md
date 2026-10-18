# Kubernetes Service Accounts

This guide explains how Kubernetes ServiceAccounts provide identities for workloads, how their credentials are made available to Pods, and how to grant a workload only the API permissions it needs using RBAC.

The hands-on example creates a ServiceAccount that can get, list, and watch Pods in the `default` namespace, then assigns it to a Pod.

## 1. ServiceAccount Concepts

Kubernetes needs to authenticate API requests and authorize what each identity can do.

- **Users and groups** commonly represent people or external identities.
- **ServiceAccounts** represent processes, applications, and other workloads that run in a cluster.
- **A ServiceAccount provides identity.** It does not, by itself, grant broad access to the Kubernetes API.
- **RBAC controls permissions.** Roles describe allowed actions, and bindings grant those permissions to identities.
- **A token is a credential** a workload can use to authenticate as its ServiceAccount.

Keep these concepts separate: **identity is not the same as permission**, and a token is a credential for that identity.

## 2. The Default ServiceAccount

Each namespace has a `default` ServiceAccount. If a Pod does not specify a ServiceAccount, Kubernetes normally assigns that namespace's `default` ServiceAccount.

Create a sample Pod:

```bash
kubectl run my-pod --image=nginx --namespace=default
kubectl get pod my-pod --namespace=default
kubectl describe pod my-pod --namespace=default
```

In the Pod description, check the `Service Account` field. It should show `default`. To see ServiceAccounts across namespaces:

```bash
kubectl get serviceaccounts --all-namespaces
```

`sa` is a kubectl shorthand for `serviceaccount`, and `-A` is shorthand for `--all-namespaces`.

## 3. ServiceAccount Credentials in a Pod

When automatic token mounting is enabled, Kubernetes makes ServiceAccount credentials available to the Pod. A common mount path is:

```text
/var/run/secrets/kubernetes.io/serviceaccount
```

Inspect the sample Pod without printing or copying its token:

```bash
kubectl exec -it my-pod --namespace=default -- sh
cd /var/run/secrets/kubernetes.io/serviceaccount
ls
exit
```

Depending on the Kubernetes version and configuration, the projected files commonly include:

| File | Purpose |
|------|---------|
| `ca.crt` | CA certificate used to verify the Kubernetes API server |
| `namespace` | Namespace associated with the Pod |
| `token` | Credential used to authenticate to the Kubernetes API server |

Modern Kubernetes generally uses short-lived, projected ServiceAccount tokens rather than manually created, long-lived token Secrets. Token details vary by version and configuration. Many tokens are JWTs whose payload claims can be decoded, but decoding does **not** verify a token. Treat tokens as secrets; do not paste a live token into an external website or share it.

## 4. Disable Automatic Token Mounting

If an application does not need to call the Kubernetes API, you can disable automatic ServiceAccount token mounting for its Pod. First remove the earlier sample Pod so the name can be reused:

```bash
kubectl delete pod my-pod --namespace=default
```

Create `pod-no-token.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  namespace: default
spec:
  automountServiceAccountToken: false
  containers:
    - name: nginx
      image: nginx:stable
```

Apply and inspect it:

```bash
kubectl apply -f pod-no-token.yaml
kubectl get pod my-pod --namespace=default
kubectl describe pod my-pod --namespace=default
```

The Pod is still associated with the namespace's `default` ServiceAccount, but Kubernetes does not automatically mount that ServiceAccount's token into this Pod. This setting can break an application that relies on the mounted credential.

Clean up before continuing:

```bash
kubectl delete pod my-pod --namespace=default
```

## 5. Create a Custom ServiceAccount

Create and inspect a ServiceAccount named `my-sa` in the `default` namespace:

```bash
kubectl create serviceaccount my-sa --namespace=default
kubectl get serviceaccounts --namespace=default
kubectl describe serviceaccount my-sa --namespace=default
```

Creating a ServiceAccount does not grant it permissions. The next section uses RBAC to grant only the Pod access required by the example.

To request a token explicitly, use:

```bash
kubectl create token my-sa --namespace=default
```

This prints sensitive credential material to the terminal. The command requests a token; it is separate from the normal mechanism by which Kubernetes mounts a token into a Pod.

## 6. Grant Pod Read Permissions with RBAC

The example grants `my-sa` permission to `get`, `list`, and `watch` Pods in the `default` namespace. It does not grant permission to create or delete Pods.

Create `role.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

The empty API group (`""`) is the core API group, which includes Pods. The Role is namespaced, so these permissions apply to resources in `default`.

Create `rolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: ServiceAccount
    name: my-sa
    namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

The RoleBinding connects the `my-sa` ServiceAccount in `default` to the `pod-reader` Role in that namespace. Apply both objects:

```bash
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
```

## 7. Assign the ServiceAccount to a Pod

Create `pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: default
spec:
  serviceAccountName: my-sa
  containers:
    - name: nginx
      image: nginx:stable
```

The `serviceAccountName` field selects the identity Kubernetes assigns to the Pod. Apply the manifest and verify the assignment:

```bash
kubectl apply -f pod.yaml
kubectl get pod nginx --namespace=default
kubectl describe pod nginx --namespace=default
```

The Pod description should show `my-sa` as its ServiceAccount. If automatic token mounting is enabled, the Pod may also have a projected volume containing its credentials.

## 8. Verify the Permissions

Use `kubectl auth can-i` to check whether the ServiceAccount is allowed to perform each action:

```bash
kubectl auth can-i get pods \
  --as=system:serviceaccount:default:my-sa \
  --namespace=default

kubectl auth can-i list pods \
  --as=system:serviceaccount:default:my-sa \
  --namespace=default

kubectl auth can-i watch pods \
  --as=system:serviceaccount:default:my-sa \
  --namespace=default
```

The expected result for each command is `yes`, assuming no other authorization configuration changes the outcome.

The impersonated identity format is:

```text
system:serviceaccount:NAMESPACE:SERVICE_ACCOUNT_NAME
```

For this example, the namespace is `default` and the ServiceAccount is `my-sa`. The caller running `kubectl auth can-i --as=...` must itself be allowed to impersonate that identity.

## 9. Quick Reference

| Goal | Resource or field |
|------|-------------------|
| Give a workload an identity | `ServiceAccount` |
| Select the identity for a Pod | `spec.serviceAccountName` |
| Describe allowed API actions | `Role` or `ClusterRole` |
| Grant permissions to an identity | `RoleBinding` or `ClusterRoleBinding` |
| Avoid automatic credentials in a Pod | `spec.automountServiceAccountToken: false` |
| Check an authorization decision | `kubectl auth can-i` |

Use the narrowest permissions and scope that meet the workload's needs. A ServiceAccount, token, and RBAC grant serve different purposes: the ServiceAccount is the identity, the token is a credential, and RBAC defines the permissions.

## 10. Summary

- Kubernetes assigns a namespace's `default` ServiceAccount to a Pod when no other ServiceAccount is specified.
- A ServiceAccount provides a workload identity; it does not automatically grant broad API permissions.
- Kubernetes can project a short-lived token into a Pod for API authentication. Treat tokens as sensitive credentials.
- Set `automountServiceAccountToken: false` when a Pod does not need an automatically mounted token.
- Use RBAC Roles and bindings to grant only the required permissions within the intended namespace.
- Set `spec.serviceAccountName` to assign a custom ServiceAccount to a Pod.
- Use `kubectl auth can-i` to check authorization, remembering that the caller must be allowed to impersonate the ServiceAccount.
