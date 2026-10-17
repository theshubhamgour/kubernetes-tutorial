# Kubernetes RBAC: Roles, RoleBindings, and Verbs

This guide explains Kubernetes Role-Based Access Control (RBAC) through a namespace-scoped Pod reader example. It walks through each part of a `Role`, gives special attention to what `get`, `list`, and `watch` mean, and shows how to grant and verify those permissions for a ServiceAccount.

## 1. Introduction

Kubernetes RBAC controls which identities can perform which actions on which Kubernetes resources.

For example, a developer who needs to inspect Pods does not necessarily need permission to delete them, change Deployments, or read Secrets. RBAC lets administrators grant only the access required for a task.

This tutorial creates a ServiceAccount named `pod-reader` and grants it permission to get, list, and watch Pods in the `rbac-demo` namespace. The permission does not, by itself, grant access to Pods in other namespaces, permission to delete Pods, or permission to read Secrets.

## 2. The Three Parts of an RBAC Grant

An RBAC permission grant involves three concepts:

| Question | Kubernetes object | Purpose |
|----------|------------------|---------|
| Who needs access? | User, group, or ServiceAccount | The identity that makes API requests |
| What may they do? | Role or ClusterRole | The allowed actions and resources |
| Where are those permissions granted? | RoleBinding or ClusterRoleBinding | Connects the identity to a Role or ClusterRole |

The relationship in this example is:

```text
ServiceAccount (pod-reader)
          |
          v
RoleBinding (pod-reader-binding)
          |
          v
Role (pod-reader-role)
          |
          v
get, list, and watch Pods in rbac-demo
```

A `Role` or `ClusterRole` only describes permissions; creating one does not assign those permissions to anyone. A binding grants the referenced permissions to its subjects.

## 3. Role, RoleBinding, ClusterRole, and ClusterRoleBinding

RBAC has two kinds of permission definitions and two kinds of bindings. It helps to separate **what permissions are described** from **where those permissions are granted**:

| Object | What it does | Scope and use |
|--------|--------------|---------------|
| `Role` | Defines allowed verbs on resources. | A namespaced permission definition. It can grant access to namespaced resources in its namespace, not to cluster-scoped resources such as Nodes. |
| `RoleBinding` | Grants a Role or ClusterRole to users, groups, or ServiceAccounts. | Grants permissions within the RoleBinding's namespace. |
| `ClusterRole` | Defines allowed verbs on resources. | A cluster-scoped and reusable permission definition. It can describe access to namespaced resources, cluster-scoped resources, and non-resource URL paths. |
| `ClusterRoleBinding` | Grants a ClusterRole to users, groups, or ServiceAccounts. | Grants the ClusterRole's permissions across the cluster. |

### Role: namespace-scoped permissions

A `Role` is a named set of permission rules associated with one namespace. For example, `pod-reader-role` in `rbac-demo` describes permission to get, list, and watch Pods in `rbac-demo`. The Role does not say who receives those permissions; a RoleBinding must grant it to an identity.

A Role is appropriate when the intended access is limited to namespaced resources in one namespace. It cannot grant permission to cluster-scoped resources such as Nodes.

### RoleBinding: grant permissions in one namespace

A `RoleBinding` connects one or more **subjects** (users, groups, or ServiceAccounts) to a permission definition through its `roleRef`.

The RoleBinding's own namespace determines where it grants access to namespaced resources. It can reference:

1. A `Role` in that same namespace. This grants that Role's permissions in that namespace.
2. A `ClusterRole`. This grants the ClusterRole's permissions only within the RoleBinding's namespace.

That second option is useful for reusing a common ClusterRole without granting it across the entire cluster. For example, RoleBindings to a read-only ClusterRole can grant read access to Pods separately in `development` and `staging`, without granting access in `production`.

A RoleBinding does not turn a ClusterRole's cluster-scoped resource permissions into namespace permissions. For example, binding a ClusterRole that includes access to Nodes with a RoleBinding does not grant access to Nodes; use a ClusterRoleBinding if cluster-wide access to Nodes is intended. Non-resource URL permissions also require a ClusterRoleBinding.

### ClusterRole: reusable or cluster-level permissions

A `ClusterRole` is a permission definition that is not tied to one namespace. It can be reused by RoleBindings in multiple namespaces. It can also define permissions for cluster-scoped resources, such as Nodes, which a namespaced Role cannot authorize.

Creating a ClusterRole alone does **not** give anyone access. Its scope as a definition should not be confused with the scope of the grant: the binding determines which identities receive the permissions and where they apply.

### ClusterRoleBinding: grant a ClusterRole cluster-wide

A `ClusterRoleBinding` connects subjects to a ClusterRole across the cluster. When its ClusterRole grants access to namespaced resources, the grant applies in all namespaces; it can also grant access to cluster-scoped resources named in the ClusterRole.

Use a ClusterRoleBinding only when cluster-wide access is intended. It is broader than a RoleBinding, so it should be reviewed carefully.

### Role vs ClusterRole, and their bindings

| Comparison | First object | Second object |
|------------|--------------|---------------|
| Permission definition | `Role`: namespaced definition for namespaced resources | `ClusterRole`: cluster-scoped reusable definition; may include cluster-scoped resources |
| Binding | `RoleBinding`: grants in its namespace; can reference a Role or ClusterRole | `ClusterRoleBinding`: grants a ClusterRole across the cluster |

The key distinction is that **a ClusterRole used by a RoleBinding is still limited to that RoleBinding's namespace**. A ClusterRoleBinding is what grants the ClusterRole cluster-wide.

For this tutorial, the requirement is only to view Pods in `rbac-demo`, so a `Role` plus a `RoleBinding` is the narrowest fit. Use the narrowest scope that meets the requirement.

## 4. The Role Manifest

Here is the Role used in this example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
  namespace: rbac-demo
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

The rule can be read as:

> In the `rbac-demo` namespace, allow the subject receiving this Role to get, list, and watch Pod resources in the core API group.

### `apiVersion: rbac.authorization.k8s.io/v1`

`apiVersion` tells Kubernetes which API group and version define this object. Roles and RoleBindings are RBAC API resources, so they use `rbac.authorization.k8s.io/v1`. This is distinct from core resources such as Pods, which use `apiVersion: v1`.

### `kind: Role`

`kind` tells Kubernetes what type of object to create. `Role` is a namespaced set of permissions. It does not represent a user, ServiceAccount, or running workload.

### `metadata`

Metadata identifies the Role:

- `name: pod-reader-role` is the name used to refer to this Role, including from a RoleBinding.
- `namespace: rbac-demo` places the Role in `rbac-demo` and defines the namespace in which a RoleBinding can use this Role.

The namespace must exist before the Role can be created.

### `rules`

`rules` is a list of permission rules. Each rule specifies API groups, resources, and verbs. All three dimensions matter: a verb alone does not say which resource it applies to, and a resource alone does not say which actions are allowed.

#### `apiGroups: [""]`

The empty string (`""`) refers to Kubernetes' **core API group**, sometimes informally called the legacy or core group. Pods, Services, ConfigMaps, and Secrets are examples of resources in this group. The empty string is meaningful here; it is not a wildcard and should not be replaced with `"*"` to mean “all API groups.”

Resources from other API groups use their group names. For example, Deployments belong to `apps`, while Roles belong to `rbac.authorization.k8s.io`.

#### `resources: ["pods"]`

This rule applies to the API resource named `pods`. Kubernetes RBAC uses resource names such as `pods`, usually in their plural form. Because this rule names only Pods, it does not authorize access to Secrets, Services, or Deployments.

#### `verbs: ["get", "list", "watch"]`

A **verb** is an API action that an identity is allowed to perform on the specified resource. Kubernetes RBAC is allow-based: this list grants only the named actions in this rule. It does not grant every action related to Pods.

| Verb | Meaning for Pods | Example request |
|------|------------------|-----------------|
| `get` | Retrieve one named Pod's API object. | `kubectl get pod demo-pod -n rbac-demo` |
| `list` | Retrieve a collection of Pods, optionally filtered by selectors. | `kubectl get pods -n rbac-demo` |
| `watch` | Subscribe to a stream of changes to Pods, such as additions, updates, or deletions. | `kubectl get pods -n rbac-demo --watch` |

These are separate permissions. Granting `list` does not automatically grant `get` or `watch`, and granting `get` does not let an identity list every Pod.

`watch` does not mean that the identity may change a Pod. It means the identity may observe change events through the Kubernetes API. A watch is commonly used by controllers and tools that need to keep their view of resources up to date.

Similarly, permission to `get`, `list`, or `watch` a Pod does not allow the identity to create, edit, patch, or delete Pods. Those are different actions and must be granted explicitly if they are needed.

### Common Kubernetes RBAC verbs

The exact actions depend on the resource, but these common verbs are useful to recognize:

| Verb | General meaning |
|------|-----------------|
| `get` | Read one named resource. |
| `list` | Read a collection of resources. |
| `watch` | Receive a stream of resource changes. |
| `create` | Create a resource. |
| `update` | Replace or update an existing resource. |
| `patch` | Apply a partial change to an existing resource. |
| `delete` | Delete a resource. |
| `deletecollection` | Delete a collection of resources. |

Do not add verbs simply because they are common. Grant only the actions the identity needs. For example, the Pod reader in this tutorial does not need `create`, `update`, `patch`, `delete`, or `deletecollection`.

## 5. Prepare a Demo Namespace

You can use an existing Kubernetes cluster, or start a separate Minikube profile for this tutorial:

```bash
minikube start --profile=rbac-demo --driver=docker
kubectl config use-context rbac-demo
kubectl get nodes
```

Confirm that the intended cluster context is selected before applying resources. Create the namespace:

```bash
kubectl create namespace rbac-demo
```

If the namespace already exists, continue without creating it again. Kubernetes resources in this guide are deliberately kept in `rbac-demo`.

## 6. Create the ServiceAccount, Sample Pod, Role, and RoleBinding

Save the following multi-document manifest as `rbac-demo.yaml`. The sample Pod gives us a resource to inspect; it does not need to run as the `pod-reader` ServiceAccount for the authorization checks in this tutorial.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader
  namespace: rbac-demo
---
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
  namespace: rbac-demo
spec:
  containers:
    - name: app
      image: busybox:1.36
      command:
        - /bin/sh
        - -c
        - sleep 3600
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
  namespace: rbac-demo
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: rbac-demo
subjects:
  - kind: ServiceAccount
    name: pod-reader
    namespace: rbac-demo
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader-role
```

### What the other objects do

- **ServiceAccount:** `pod-reader` is the identity that will receive the permissions. Creating a ServiceAccount does not automatically grant it permission to read Pods.
- **Sample Pod:** `demo-pod` is an ordinary workload used to demonstrate which Pod API requests are authorized.
- **Role:** `pod-reader-role` declares the allowed actions on Pods in `rbac-demo`.
- **RoleBinding:** `pod-reader-binding` connects the ServiceAccount to the Role. Its `subjects` identify the recipient, and its `roleRef` identifies the Role whose permissions are granted.

The RoleBinding is also in `rbac-demo`. A RoleBinding that references this Role grants its namespaced permissions in the RoleBinding's namespace. The ServiceAccount subject includes its namespace because ServiceAccounts are namespaced identities.

The `roleRef` identifies a Role in the same namespace as the RoleBinding. The `roleRef` is immutable after creation; to change which Role it references, delete and recreate the RoleBinding.

## 7. Apply and Inspect the Resources

Apply only the manifest you created:

```bash
kubectl apply -f rbac-demo.yaml
```

Check that the objects exist:

```bash
kubectl get serviceaccount pod-reader -n rbac-demo
kubectl get role pod-reader-role -n rbac-demo
kubectl get rolebinding pod-reader-binding -n rbac-demo
kubectl get pod demo-pod -n rbac-demo
```

If the Pod is still starting, wait until it is ready before using it for a live `get` test:

```bash
kubectl wait --for=condition=Ready pod/demo-pod -n rbac-demo --timeout=120s
```

## 8. Verify the Permissions

`kubectl auth can-i` asks the Kubernetes authorization system whether an identity may perform a particular action. Use `--as` to check as the ServiceAccount:

```bash
kubectl auth can-i list pods \
  -n rbac-demo \
  --as=system:serviceaccount:rbac-demo:pod-reader
```

Expected output:

```text
yes
```

The impersonated identity string has the form `system:serviceaccount:<namespace>:<serviceaccount-name>`. The account running `kubectl auth can-i --as=...` must itself be allowed to impersonate that identity. If Kubernetes returns an authorization error instead of `yes` or `no`, use an appropriately authorized administrator context or ask a cluster administrator to perform the check.

Check each granted and ungranted action:

```bash
# Allowed: retrieve the named Pod.
kubectl auth can-i get pods/demo-pod \
  -n rbac-demo \
  --as=system:serviceaccount:rbac-demo:pod-reader

# Allowed: list Pods.
kubectl auth can-i list pods \
  -n rbac-demo \
  --as=system:serviceaccount:rbac-demo:pod-reader

# Allowed: watch Pods.
kubectl auth can-i watch pods \
  -n rbac-demo \
  --as=system:serviceaccount:rbac-demo:pod-reader

# Not granted by this Role: delete Pods.
kubectl auth can-i delete pods \
  -n rbac-demo \
  --as=system:serviceaccount:rbac-demo:pod-reader

# Not granted by this Role: read Secrets.
kubectl auth can-i get secrets \
  -n rbac-demo \
  --as=system:serviceaccount:rbac-demo:pod-reader

# Not granted by this namespaced RoleBinding in another namespace.
kubectl auth can-i list pods \
  -n default \
  --as=system:serviceaccount:rbac-demo:pod-reader
```

The expected results, in order, are `yes`, `yes`, `yes`, `no`, `no`, and `no`, assuming no other RoleBindings or authorization mechanisms grant this identity additional access.

The `kubectl auth can-i` checks verify authorization; they do not log in as the ServiceAccount or prove that an application has credentials to authenticate as it. For actual API requests, the caller must also authenticate as the identity.

## 9. Important RBAC Security Notes

- **Permissions are additive.** Kubernetes RBAC does not have a deny rule in a Role. If another binding grants the same identity more access, that additional access is combined with this Role's permissions.
- **A Role is not a binding.** A Role without a RoleBinding does not grant its permissions to an identity.
- **Keep access narrow.** Specify the API groups, resources, verbs, and namespace needed. Avoid broad wildcards such as `"*"` unless there is a carefully justified need.
- **Reading Pods can expose workload details.** Pod objects can include configuration and references to Secrets. Avoid granting read access casually, and do not assume permission to read Pod objects is equivalent to permission to read Secret objects.
- **RBAC controls Kubernetes API requests.** It does not control what a process can do inside a container or replace other security controls.

## 10. Cleanup

Delete the demo resources:

```bash
kubectl delete -f rbac-demo.yaml
kubectl delete namespace rbac-demo
```

If you created the dedicated Minikube profile and no longer need it, delete that profile:

```bash
minikube delete --profile=rbac-demo
```

Only delete the namespace or profile if they are dedicated to this demo; these commands remove resources in them.

## 11. Summary

- A `Role` defines which actions are allowed on which resources in a namespace.
- A `RoleBinding` grants a Role's permissions to a user, group, or ServiceAccount.
- In a rule, `apiGroups`, `resources`, and `verbs` together describe the permitted API requests.
- `get` reads one named object, `list` reads a collection, and `watch` streams changes.
- These verbs do not grant permission to create, update, patch, or delete Pods.
- Use `kubectl auth can-i` to verify expected authorization, and consider all bindings that may grant the identity additional permissions.