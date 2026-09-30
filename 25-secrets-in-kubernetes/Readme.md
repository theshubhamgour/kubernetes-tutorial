 # Kubernetes Secrets

This tutorial explains how Kubernetes Secrets store and provide sensitive configuration such as passwords, API tokens, SSH keys, TLS certificates, and registry credentials.

## 1. Scope

This lesson focuses on:

- what a Secret is
- how Secrets differ from ConfigMaps
- creating a Secret with `stringData`
- reading a Secret as environment variables
- importing Secret keys with `envFrom`
- mounting Secret values as files
- understanding Secret updates
- RBAC, encryption at rest, and Git security
- immutable Secrets and common troubleshooting commands

---

## 2. Problem Statement

Applications often need sensitive values such as:

- `DATABASE_USERNAME=admin`
- `DATABASE_PASSWORD=MyPassword123`
- an API token
- an SSH private key
- a TLS certificate and private key

Putting these values directly in application code, a container image, or a Pod manifest makes them difficult to manage and easy to expose.

A Secret lets the application image remain unchanged while credentials are managed separately:

```text
Application
		 |
		 v
Kubernetes Secret
		 |
		 v
Sensitive values
```

This separates application code from credentials, but a Secret is not automatically a complete security solution. Access control and encryption must also be configured correctly.

---

## 3. What is a Secret?

A Secret is a Kubernetes object designed to hold small amounts of sensitive data.

Common examples include:

- database usernames and passwords
- API tokens
- SSH keys
- TLS certificates and private keys
- private container registry credentials

Secrets are namespaced. A Pod can reference a Secret only in the same namespace unless another Kubernetes feature handles the credential, such as image pulling.

---

## 4. ConfigMap vs Secret

| Object | Used for | Examples |
| --- | --- | --- |
| ConfigMap | non-sensitive configuration | environment, log level, service host |
| Secret | sensitive configuration | password, token, private key, certificate |

Use a ConfigMap for values that are safe to expose to users who can read normal application configuration. Use a Secret for confidential values.

---

## 5. Secret Data is Base64-Encoded, Not Automatically Encrypted

This is an important distinction.

Values in the `data` field are Base64-encoded. Base64 is an encoding format, not encryption:

```text
admin
```

becomes:

```text
YWRtaW4=
```

Anyone who can read the encoded value can decode it. Kubernetes Secrets provide a purpose-built API object and integration points, but production security also requires:

- RBAC and least-privilege access
- encryption at rest for Secret data in etcd
- secure cluster administration
- careful handling in logs, terminals, and CI/CD systems

---

## 6. Create the First Secret

Create a file named `db-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
	name: db-credentials
type: Opaque
stringData:
	username: admin
	password: MyPassword123
```

### Important fields

- `apiVersion: v1` uses the Kubernetes core API
- `kind: Secret` creates a Secret resource
- `metadata.name` gives the Secret its name
- `type: Opaque` is the general-purpose type for user-defined data
- `stringData` accepts plain strings and lets Kubernetes create the stored `data` representation

The example values are for learning only. Do not use them as real credentials.

Apply the Secret:

```bash
kubectl apply -f db-secret.yaml
```

Check it:

```bash
kubectl get secrets
kubectl describe secret db-credentials
```

The `describe` output shows the Secret type and key names with their byte sizes, but does not print the values.

---

## 7. Inspect and Decode a Secret

To view the stored representation:

```bash
kubectl get secret db-credentials -o yaml
```

You will see output similar to:

```yaml
data:
	password: TXlQYXNzd29yZDEyMw==
	username: YWRtaW4=
```

To decode a value for this demonstration:

```bash
kubectl get secret db-credentials \
	-o jsonpath='{.data.password}' | base64 --decode
printf '\\n'
```

Expected output:

```text
MyPassword123
```

Be careful with commands that print Secret values. Terminal history, shell output, and CI/CD logs can expose credentials.

---

## 8. Secret Types

Kubernetes provides several built-in Secret types:

| Type | Intended use |
| --- | --- |
| `Opaque` | arbitrary application data; the default general-purpose type |
| `kubernetes.io/dockerconfigjson` | private container registry credentials |
| `kubernetes.io/basic-auth` | basic authentication credentials |
| `kubernetes.io/ssh-auth` | SSH authentication data, usually an SSH private key |
| `kubernetes.io/tls` | TLS certificate and private key |
| `kubernetes.io/service-account-token` | legacy long-lived ServiceAccount token Secrets |
| `bootstrap.kubernetes.io/token` | cluster bootstrap token data |
| `kubernetes.io/dockercfg` | older Docker registry credential format |

For database credentials, `Opaque` is the appropriate type.

For ServiceAccounts, Kubernetes recommends short-lived tokens from the TokenRequest API instead of manually creating long-lived token Secrets.

---

## 9. Use a Secret as Environment Variables

Create a file named `secret-env-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: secret-env-pod
spec:
	containers:
		- name: app
			image: busybox
			command:
				- sh
				- -c
				- sleep 3600
			env:
				- name: DB_USERNAME
					valueFrom:
						secretKeyRef:
							name: db-credentials
							key: username
				- name: DB_PASSWORD
					valueFrom:
						secretKeyRef:
							name: db-credentials
							key: password
```

The `secretKeyRef` block means:

- read the Secret named `db-credentials`
- read one specific key from that Secret
- expose the value under the chosen environment variable name

Apply and check the Pod:

```bash
kubectl apply -f secret-env-pod.yaml
kubectl get pod secret-env-pod
```

For this local demonstration only, verify the values with:

```bash
kubectl exec secret-env-pod -- printenv | grep -E 'DB_USERNAME|DB_PASSWORD'
```

Expected output:

```text
DB_USERNAME=admin
DB_PASSWORD=MyPassword123
```

Avoid printing credentials in production logs, command output, or automated pipelines.

### Required and optional Secret references

By default, a `secretKeyRef` is required. If the Secret or key is missing, the container cannot start successfully. An optional reference can be declared when appropriate:

```yaml
secretKeyRef:
	name: db-credentials
	key: password
	optional: true
```

Use optional references deliberately because they can allow an application to start without a value it normally expects.

---

## 10. Import All Secret Keys with `envFrom`

Create a file named `secret-envfrom-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: secret-envfrom-pod
spec:
	containers:
		- name: app
			image: busybox
			command:
				- sh
				- -c
				- sleep 3600
			envFrom:
				- secretRef:
						name: db-credentials
```

Apply it:

```bash
kubectl apply -f secret-envfrom-pod.yaml
kubectl get pod secret-envfrom-pod
```

With `envFrom`, Kubernetes uses the Secret keys as the environment variable names:

```bash
kubectl exec secret-envfrom-pod -- printenv | grep -E 'username|password'
```

Expected output:

```text
username=admin
password=MyPassword123
```

The difference is:

- `secretKeyRef` selects a key and lets you choose the environment variable name
- `envFrom` imports all valid Secret keys using their existing names

---

## 11. Mount a Secret as Files

Some applications expect credentials in files instead of environment variables.

Create a file named `secret-volume-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: secret-volume-pod
spec:
	containers:
		- name: app
			image: busybox
			command:
				- sh
				- -c
				- sleep 3600
			volumeMounts:
				- name: secret-volume
					mountPath: /etc/credentials
					readOnly: true
	volumes:
		- name: secret-volume
			secret:
				secretName: db-credentials
```

The Secret keys become files in the mount directory:

```text
/etc/credentials/username
/etc/credentials/password
```

Apply and verify it:

```bash
kubectl apply -f secret-volume-pod.yaml
kubectl get pod secret-volume-pod
kubectl exec secret-volume-pod -- ls -la /etc/credentials
kubectl exec secret-volume-pod -- cat /etc/credentials/username
kubectl exec secret-volume-pod -- cat /etc/credentials/password
```

Expected values:

```text
admin
MyPassword123
```

Secret volume mounts are read-only from the container's point of view. The application can read the files but should not modify the Secret through the mounted filesystem.

On Linux nodes, Secret volume data is commonly backed by `tmpfs`, a RAM-backed filesystem. The exact output of filesystem inspection can vary by operating system and container runtime, so treat this as an implementation detail rather than an application contract.

---

## 12. Updating a Secret

Change the password in `db-secret.yaml`:

```yaml
stringData:
	username: admin
	password: NewPassword456
```

Apply the update:

```bash
kubectl apply -f db-secret.yaml
```

### Secret mounted as a file

Kubernetes eventually updates a normal Secret volume after the Secret changes. Check the file after propagation:

```bash
kubectl exec secret-volume-pod -- cat /etc/credentials/password
```

Expected output:

```text
NewPassword456
```

The application may still need to reload the file or restart to use the new value.

### Secret consumed as an environment variable

Environment variables are created when the container process starts. Updating the Secret does not rewrite the environment of an already-running process:

```bash
kubectl exec secret-env-pod -- printenv | grep DB_PASSWORD
```

The existing Pod still has:

```text
DB_PASSWORD=MyPassword123
```

Recreate the Pod to start a new process with the updated value:

```bash
kubectl delete pod secret-env-pod
kubectl apply -f secret-env-pod.yaml
kubectl exec secret-env-pod -- printenv | grep DB_PASSWORD
```

The same rule applies to `envFrom`.

### Update behavior summary

| Secret usage | Existing Pod receives updates? |
| --- | --- |
| environment variable | no; recreate or restart the Pod |
| `envFrom` | no; recreate or restart the Pod |
| mounted Secret file | eventually, after Kubernetes propagation |

---

## 13. Secret Security

A Secret should be protected as sensitive data. Think of security as a combination of:

```text
Secret
	+ RBAC
	+ encryption at rest
	+ least privilege
	+ secure operational practices
```

### RBAC

Anyone with permission to read Secrets may be able to retrieve their values. Avoid granting broad permissions such as `get`, `list`, or `watch` on Secrets unless they are required.

Review access with:

```bash
kubectl auth can-i get secrets
kubectl auth can-i list secrets
```

### Encryption at rest

Secret objects are stored in etcd. Cluster administrators should configure encryption at rest so Secret data is protected if the underlying etcd storage is accessed.

### Secrets in Git

Do not commit real credentials to Git:

```yaml
stringData:
	password: real-production-password
```

Replacing the plain value with Base64 does not make it safe. Use an external secret-management system, encrypted Git workflow, or controlled CI/CD secret injection for production credentials.

---

## 14. Secret Size Limit

An individual Secret is limited to 1 MiB. Secrets are intended for small credentials and certificates, not large files or general-purpose storage.

---

## 15. Immutable Secret

Mark a Secret as immutable when its data must not change:

```yaml
apiVersion: v1
kind: Secret
metadata:
	name: immutable-secret
type: Opaque
stringData:
	API_TOKEN: example-token
immutable: true
```

Once a Secret is immutable:

- its data cannot be changed
- accidental updates are prevented
- a new Secret must be created when different data is needed

This can be useful when a Secret is referenced by many Pods and its value should remain fixed.

---

## 16. Create a Secret Imperatively

For quick testing, create a generic Secret from the command line:

```bash
kubectl create secret generic db-credentials \
	--from-literal=username=admin \
	--from-literal=password='MyPassword123'
```

The command means:

- `create secret` creates a Secret
- `generic` creates an `Opaque` Secret
- `--from-literal` takes each value directly from the command line

This is convenient for experiments, but shell history or process inspection can expose the credential. Do not treat this as a production secret-management workflow.

---

## 17. Troubleshooting

If a Pod references a Secret that does not exist, or a required key is missing, inspect the Secret and Pod events:

```bash
kubectl get secret db-credentials
kubectl describe secret db-credentials
kubectl describe pod secret-env-pod
kubectl get events --sort-by=.lastTimestamp
```

Check that:

- the Secret exists in the Pod's namespace
- the Secret name is spelled correctly
- the referenced key exists
- the Pod is using the expected namespace
- the container has restarted after an environment-variable change

---

## 18. Cleanup

Remove the demonstration resources:

```bash
kubectl delete pod secret-env-pod secret-envfrom-pod secret-volume-pod
kubectl delete secret db-credentials
```

---

## 19. Quick Summary

- Secret is used for sensitive configuration data
- `Opaque` is the general-purpose Secret type
- `stringData` accepts plain strings when creating a Secret
- Secret values in `data` are Base64-encoded, not automatically encrypted
- `secretKeyRef` injects one key as a chosen environment variable
- `envFrom` imports all Secret keys as environment variables
- Secret volumes expose keys as read-only files
- environment variables do not update in an existing process
- mounted Secret files can eventually receive updated values
- RBAC and least privilege control who can access Secrets
- encryption at rest protects Secret data stored in etcd
- real credentials should not be committed to Git
- Secrets are limited to 1 MiB and are not general-purpose file storage

Kubernetes Secrets separate credentials from application code, but they should always be used together with sound access control and secret-management practices.
