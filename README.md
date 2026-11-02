<div align="center">

# ☸️ Kubernetes Tutorial for Beginners

**A complete, free, hands-on Kubernetes course: 36 modules, 40 videos and 30 hours of content**

[![Status: Complete](https://img.shields.io/badge/Status-Complete-2EA043?style=flat-square)](#-course-modules)
[![Modules: 36](https://img.shields.io/badge/Modules-36-326CE5?style=flat-square&logo=kubernetes&logoColor=white)](#-course-modules)
[![Watch the playlist](https://img.shields.io/badge/Watch-Full%20Playlist-FF0000?style=flat-square&logo=youtube&logoColor=white)](https://www.youtube.com/playlist?list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-)

[![Watch the Kubernetes course on YouTube](https://i.ytimg.com/vi/dlmbhY4RdrQ/hqdefault.jpg)](https://www.youtube.com/playlist?list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-)

**[▶ Watch the full course on YouTube](https://www.youtube.com/playlist?list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-)** · **[Subscribe to the channel](https://www.youtube.com/shubhamgourtech)**

</div>

This repository holds the notes and YAML manifests for the course. It starts with why Kubernetes exists, then moves on to running, exposing, storing, configuring, scaling and securing real applications on a cluster.

Each concept starts with a simple explanation, then gets built hands-on: you write the YAML yourself, break things on purpose and troubleshoot them.

---

## 🎯 Who this course is for

- Beginners starting Kubernetes for the first time
- DevOps, cloud and platform engineers moving from Docker to Kubernetes
- Developers who want to deploy their own apps on Kubernetes
- Anyone preparing for Kubernetes interviews or the CKA and CKAD exams

## ✅ Prerequisites

- Basic Docker knowledge. New to containers? Start with [docker-tutorial](https://github.com/theshubhamgour/docker-tutorial).
- Comfort with the Linux command line
- A machine that can run a local cluster, or Linux VMs for Kubeadm. [Module 1](./1-install-kubernetes) covers the setup.

## 🚀 How to use this repository

```bash
git clone https://github.com/theshubhamgour/kubernetes-tutorial.git
cd kubernetes-tutorial
```

1. **Follow the modules in order.** Each lesson builds on the previous one.
2. **Watch the video, then open that module's folder** for its notes and manifests.
3. **Type the manifests yourself** instead of copy-pasting, then apply them:

   ```bash
   kubectl apply -f <manifest>.yml
   kubectl get all
   ```

4. **Clean up** before you move on:

   ```bash
   kubectl delete -f <manifest>.yml
   ```

---

## 📚 Course modules

### 🧭 Start here

| Lesson | Video |
| :-- | :-- |
| Course introduction | [▶ 2:35](https://www.youtube.com/watch?v=dlmbhY4RdrQ&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| Why Kubernetes? Docker vs Kubernetes | [▶ 8:27](https://www.youtube.com/watch?v=bZhN8aPksWo&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| What is Kubernetes? Orchestration and desired state | [▶ 6:54](https://www.youtube.com/watch?v=sPXJcOAuEt0&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| Kubernetes architecture: control plane and worker nodes | [▶ 27:43](https://www.youtube.com/watch?v=beYyRumKXZE&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### 🧱 Setup and core basics

| # | Module | Video |
| :-: | :-- | :-- |
| 1 | [Install a cluster: KIND, Minikube and Kubeadm](./1-install-kubernetes) | [▶ 48:35](https://www.youtube.com/watch?v=wgvZfHApoyM&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 2 | [Key Kubernetes terminology](./2-kubernetes-terminologies) | [▶ 16:05](https://www.youtube.com/watch?v=sl1ZY19OTn0&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 3 | [Essential kubectl commands](./3-kubectl-kubernetes) | [▶ 30:07](https://www.youtube.com/watch?v=ahdUpVSDn9k&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 4 | [Pods: multi-container, sidecar and pause containers](./4-pods-kubernetes) | [▶ 20:20](https://www.youtube.com/watch?v=afo8RyshkGY&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 5 | [Writing Kubernetes YAML manifests](./5-yaml-for-kubernetes) | [▶ 53:50](https://www.youtube.com/watch?v=nRbJtb8aqKk&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### 🏷️ Organizing resources

| # | Module | Video |
| :-: | :-- | :-- |
| 6 | [Namespaces](./6-namespaces-in-kubernetes) | [▶ 34:51](https://www.youtube.com/watch?v=9JE1av22XSA&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 7 | [Labels and selectors](./7-labels-and-selectors) | [▶ 59:18](https://www.youtube.com/watch?v=x56bRp-iwaY&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### ⚙️ Workloads

| # | Module | Video |
| :-: | :-- | :-- |
| 8 | [Deployments](./8-deployments-in-kubernetes) | [▶ 35:41](https://www.youtube.com/watch?v=thWniufHp8Q&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 9 | [ReplicaSet vs Deployment and self-healing](./9-replicaset-vs-deployment) | [▶ 1:18:21](https://www.youtube.com/watch?v=SElsgJbDaog&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 10 | [Rolling updates and rollbacks](./10-rolling-updates-and-rollback) | [▶ 51:42](https://www.youtube.com/watch?v=Si9cm1m51Uw&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 11 | [DaemonSets](./11-daemonsets-kubernetes) | [▶ 1:00:25](https://www.youtube.com/watch?v=pTy2w37jloE&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 12 | [Jobs and CronJobs](./12-jobs-and-cronjobs-kubernetes) | [▶ 1:27:38](https://www.youtube.com/watch?v=_taqtPauttQ&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 13 | [StatefulSets, headless Services and a MySQL demo](./13-statefulsets-in-kubernetes) | [▶ 45:36](https://www.youtube.com/watch?v=5xMud9LxWEk&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### 🌐 Networking

| # | Module | Video |
| :-: | :-- | :-- |
| 14 | [Networking basics: Pod IP, ClusterIP and Services](./14-networking-in-kubernetes) | [▶ 42:29](https://www.youtube.com/watch?v=133mAcb66ss&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 15 | [Services: port vs targetPort, Endpoints and DNS](./15-services-in-kubernetes) | [▶ 57:55](https://www.youtube.com/watch?v=ZHEv6TJziIg&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 16 | [ClusterIP vs NodePort vs LoadBalancer](./16-clusterip-nodeport-loadbalancer) | [▶ 57:14](https://www.youtube.com/watch?v=npGmIRSGD_0&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 17 | [Ingress with the NGINX Ingress Controller](./17-ingress-in-kubernetes) | [▶ 1:31:21](https://www.youtube.com/watch?v=9ZDyggVzkNU&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 18 | [Pod-to-Pod networking and CNI](./18-kubernetes-resource-networking) | [▶ 1:20:56](https://www.youtube.com/watch?v=-GnDBOMNGIk&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 19 | [Gateway API: from Ingress annotations to HTTPRoute](./19-gateway-api-kubernetes) | [▶ 1:53:55](https://www.youtube.com/watch?v=hInUhNubOZs&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### 💾 Storage

| # | Module | Video |
| :-: | :-- | :-- |
| 20 | [Volumes: emptyDir and hostPath](./20-volumes-in-kubenetes) | [▶ 1:06:23](https://www.youtube.com/watch?v=HMqIikPWLBE&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 21 | [PersistentVolumes: lifecycle and reclaim policy](./21-persistent-volumes-kubernetes) | [▶ 44:01](https://www.youtube.com/watch?v=bRn4vHuDJn8&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 22 | [PersistentVolumeClaims](./22-pvc-in-kubernetes) | [▶ 24:09](https://www.youtube.com/watch?v=ey5-3TGUCTc&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 23 | [StorageClass and dynamic provisioning](./23-storageclass-in-kuberbetes) | [▶ 33:19](https://www.youtube.com/watch?v=6PXMndb4oY0&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### 🔧 Configuration and reliability

| # | Module | Video |
| :-: | :-- | :-- |
| 24 | [ConfigMaps](./24-configmaps-kubernetes) | [▶ 57:02](https://www.youtube.com/watch?v=uKnlrU6kvc0&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 25 | [Secrets](./25-secrets-in-kubernetes) | [▶ 59:54](https://www.youtube.com/watch?v=lqljr5wb15E&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 26 | [Probes: liveness, readiness and startup](./26-probes-in-kubernetes) | [▶ 33:21](https://www.youtube.com/watch?v=DejT5ejknM4&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 27 | [Requests and limits: QoS and OOMKilled](./27-requests-limits-kubernetes) | [▶ 31:42](https://www.youtube.com/watch?v=1nAsxJSsfkw&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### 📈 Autoscaling

| # | Module | Video |
| :-: | :-- | :-- |
| 28 | [Horizontal Pod Autoscaler (HPA)](./28-hpa-in-kubernetes) | [▶ 42:35](https://www.youtube.com/watch?v=fgXRoLkyehQ&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 29 | [Vertical Pod Autoscaler (VPA)](./29-vpa-in-kubernetes) | [▶ 38:30](https://www.youtube.com/watch?v=NFdaLu42PsI&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### 🔐 Security and scheduling

| # | Module | Video |
| :-: | :-- | :-- |
| 30 | [RBAC: Role, RoleBinding, ClusterRole and ClusterRoleBinding](./30-RBAC-in-kubernetes) | [▶ 44:16](https://www.youtube.com/watch?v=CmabO5t75eM&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 31 | [Service accounts and tokens](./31-service-accounts-in-kubernetes) | [▶ 34:19](https://www.youtube.com/watch?v=IajpsLD21RA&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 32 | [Taints and tolerations](./32-taints-and-tolerations-in-kubernetes) | [▶ 27:21](https://www.youtube.com/watch?v=yTLvgkQLNKU&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 33 | [Node affinity](./33-node-affinity-kubernetes) | [▶ 16:35](https://www.youtube.com/watch?v=L_mLCT8FW6c&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 34 | [Network policies: Ingress vs Egress with Calico](./34-network-policies-in-kubernetes) | [▶ 56:25](https://www.youtube.com/watch?v=t17C6RfoZ2k&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

### 🚀 Extending Kubernetes

| # | Module | Video |
| :-: | :-- | :-- |
| 35 | [Helm: create your first chart](./35-helm-in-kubernetes) | [▶ 35:54](https://www.youtube.com/watch?v=_54bTTQ5VyE&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |
| 36 | [Custom Resource Definitions (CRDs)](./36-crd-in-kubernetes) | [▶ Watch](https://www.youtube.com/watch?v=XLOXLDGV454&list=PLBr8obKbpkYvNosYrgzEayOCe1d_MY5n-) |

---

## 🤝 Contributing

The course is complete, and corrections are always welcome:

- **Found a mistake?** If there's a typo, a broken command or a manifest that fails on a current Kubernetes version, [open an issue](https://github.com/theshubhamgour/kubernetes-tutorial/issues) or send a pull request.
- **Keep pull requests small.** Stick to one module and mention the Kubernetes version you tested with.

## 📖 Official documentation

Each module links to the official pages for its topic. These are good places to start:

- [Kubernetes documentation](https://kubernetes.io/docs/home/)
- [Kubernetes basics tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Concepts](https://kubernetes.io/docs/concepts/)
- [kubectl quick reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

## 🙌 Support my work

If this course helped you, ⭐ **star this repository** so other learners can find it, and support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour

---

<div align="center">

Made by [Shubham Gour](https://github.com/theshubhamgour) · [YouTube](https://www.youtube.com/shubhamgourtech) · [Blog](https://theshubhamgour.hashnode.dev/) · [LinkedIn](https://www.linkedin.com/in/theshubhamgour/) · [Instagram](https://www.instagram.com/theshubhamgour/)

</div>
