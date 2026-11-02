# Custom Resource Definitions (CRDs) in Kubernetes

A **CustomResourceDefinition (CRD)** teaches your cluster a new resource type. After you create one, the API server serves that type like a built-in resource, so you can use `kubectl get books` the same way you use `kubectl get pods`.

This demo creates a `Book` resource type, then creates one `Book` object.

## How the demo works

| File | What it does |
| :-- | :-- |
| [`book-crd.yml`](./book-crd.yml) | Defines the new `Book` type (the CRD) |
| [`my-book.yml`](./my-book.yml) | Creates a `Book` named `my-book` (the custom resource) |

## Run the demo

Apply the CRD first, because the cluster has to know the `Book` type before it can accept a `Book`:

```bash
kubectl apply -f book-crd.yml
kubectl get crd books.demo.example.com
kubectl apply -f my-book.yml
kubectl get books
kubectl describe book my-book
```

Clean up by deleting the object, then the CRD:

```bash
kubectl delete -f my-book.yml
kubectl delete -f book-crd.yml
```

## The CRD manifest

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
 name: books.demo.example.com
spec:
 group: demo.example.com
 scope: Namespaced
 names:
  plural: books
  singular: book
  kind: Book
 versions:
  - name: v1
    served: true
    storage: true
    schema:
     openAPIV3Schema:
      type: object
      properties:
       spec:
        type: object
        properties:
         bookName:
          type: string
         author:
           type: string
         pages:
          type: integer
```

## Understanding the fields

| Field | Meaning |
| :-- | :-- |
| `metadata.name` | Must be `<plural>.<group>`, which is why it's `books.demo.example.com` |
| `spec.group` | The API group, used in `apiVersion: demo.example.com/v1` |
| `spec.scope` | `Namespaced` means each `Book` belongs to a namespace. The alternative is `Cluster` |
| `spec.names` | The names you use with `kubectl` and in YAML |
| `versions[].served` | Whether the API server serves this version |
| `versions[].storage` | Whether objects are stored in this version. Exactly one version must have this set to `true` |
| `schema.openAPIV3Schema` | Validates objects. For example, a `Book` with text in `pages` is rejected |

## 📝 Additional notes

- **A CRD only stores data:** creating a `Book` makes the API server save it, and nothing else happens. To make something happen, such as creating Pods from a custom resource, you need a **controller** watching those objects. A CRD plus a controller is the idea behind the **Operator pattern**.
- **Deleting a CRD deletes its objects:** when you delete a CRD, every custom resource of that type goes with it, so be careful on real clusters.
- **See it in the API:** `kubectl api-resources --api-group=demo.example.com` lists your new type, and `kubectl explain book.spec` shows its fields from the schema.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [Extend the Kubernetes API with CustomResourceDefinitions](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)
- [Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
