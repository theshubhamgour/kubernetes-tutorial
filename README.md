# ☸️ Kubernetes Tutorial: Zero to Production-Ready, Hands-On

### *By Shubham Gour ([@theshubhamgour](https://github.com/theshubhamgour))*

A free, module-by-module Kubernetes course. Every module has a README with the theory, the YAML manifests used on screen and the commands to run them yourself. Each one also pairs with a video on [YouTube](https://www.youtube.com/@shubhamgourtech).

🎥 **Start the series:** [Kubernetes Tutorial for Beginners: series announcement](https://www.youtube.com/watch?v=dlmbhY4RdrQ)
📅 **Status:** ongoing. New modules are added as new videos are published.

---

## 🎯 Who is this for?

- Beginners who know basic Docker and want to learn Kubernetes properly
- DevOps, cloud and platform engineers who want a hands-on refresher
- Anyone preparing for Kubernetes interviews or for the CKA and CKAD exams

## 🛠️ Prerequisites

- Comfort with the Linux command line
- Docker basics (if you're new to Docker, start with [docker-tutorial](https://github.com/theshubhamgour/docker-tutorial))
- A machine that can run a local cluster with **kind** or **Minikube**, or two or more Linux VMs for **kubeadm**. Module 1 covers all three.

## 🚀 How to use this repository

```bash
git clone https://github.com/theshubhamgour/kubernetes-tutorial.git
cd kubernetes-tutorial/1-install-kubernetes
```

1. Work through the modules **in order**, because later modules build on earlier ones.
2. Read the module's `README.md`, then apply its manifests:
   ```bash
   kubectl apply -f <manifest>.yml
   kubectl get all
   ```
3. Clean up when you're done with a module:
   ```bash
   kubectl delete -f <manifest>.yml
   ```

---

## 📺 Before you start: concepts

| Topic | Video |
| :-- | :-- |
| What is Kubernetes? | [Watch](https://www.youtube.com/watch?v=sPXJcOAuEt0) |
| Why Kubernetes? Docker vs Kubernetes | [Watch](https://www.youtube.com/watch?v=bZhN8aPksWo) |
| Kubernetes architecture: control plane and worker nodes | [Watch](https://www.youtube.com/watch?v=beYyRumKXZE) |

## 📚 Modules

### Foundations

| # | Module | Video |
| :-: | :-- | :-- |
| 1 | [Install Kubernetes: kind, Minikube and kubeadm](./1-install-kubernetes) | [Watch](https://www.youtube.com/watch?v=wgvZfHApoyM) |
| 2 | [Kubernetes terminology](./2-kubernetes-terminologies) | [Watch](https://www.youtube.com/watch?v=sl1ZY19OTn0) |
| 3 | [kubectl essentials](./3-kubectl-kubernetes) | [Watch](https://www.youtube.com/watch?v=ahdUpVSDn9k) |
| 4 | [Pods: multi-container, sidecar and pause containers](./4-pods-kubernetes) | [Watch](https://www.youtube.com/watch?v=afo8RyshkGY) |
| 5 | [YAML for Kubernetes](./5-yaml-for-kubernetes) | [Watch](https://www.youtube.com/watch?v=nRbJtb8aqKk) |
| 6 | [Namespaces](./6-namespaces-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=9JE1av22XSA) |
| 7 | [Labels and selectors](./7-labels-and-selectors) | [Watch](https://www.youtube.com/watch?v=x56bRp-iwaY) |

### Workloads

| # | Module | Video |
| :-: | :-- | :-- |
| 8 | [Deployments](./8-deployments-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=thWniufHp8Q) |
| 9 | [ReplicaSet vs Deployment](./9-replicaset-vs-deployment) | [Watch](https://www.youtube.com/watch?v=SElsgJbDaog) |
| 10 | [Rolling updates and rollbacks](./10-rolling-updates-and-rollback) | [Watch](https://www.youtube.com/watch?v=Si9cm1m51Uw) |
| 11 | [DaemonSets](./11-daemonsets-kubernetes) | [Watch](https://www.youtube.com/watch?v=pTy2w37jloE) |
| 12 | [Jobs and CronJobs](./12-jobs-and-cronjobs-kubernetes) | [Watch](https://www.youtube.com/watch?v=_taqtPauttQ) |
| 13 | [StatefulSets, headless Services and a MySQL demo](./13-statefulsets-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=5xMud9LxWEk) |

### Networking

| # | Module | Video |
| :-: | :-- | :-- |
| 14 | [Networking basics: Pod IP, ClusterIP and Services](./14-networking-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=133mAcb66ss) |
| 15 | [Services: port vs targetPort, Endpoints and DNS](./15-services-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=ZHEv6TJziIg) |
| 16 | [ClusterIP vs NodePort vs LoadBalancer](./16-clusterip-nodeport-loadbalancer) | [Watch](https://www.youtube.com/watch?v=npGmIRSGD_0) |
| 17 | [Ingress with the NGINX Ingress Controller](./17-ingress-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=9ZDyggVzkNU) |
| 18 | [Pod networking: pod-to-pod communication and CNI](./18-kubernetes-resource-networking) | [Watch](https://www.youtube.com/watch?v=-GnDBOMNGIk) |
| 19 | [Gateway API: from Ingress annotations to HTTPRoute](./19-gateway-api-kubernetes) | [Watch](https://www.youtube.com/watch?v=hInUhNubOZs) |

### Storage and configuration

| # | Module | Video |
| :-: | :-- | :-- |
| 20 | [Volumes: emptyDir and hostPath](./20-volumes-in-kubenetes) | [Watch](https://www.youtube.com/watch?v=HMqIikPWLBE) |
| 21 | [PersistentVolumes: lifecycle and reclaim policy](./21-persistent-volumes-kubernetes) | [Watch](https://www.youtube.com/watch?v=bRn4vHuDJn8) |
| 22 | [PersistentVolumeClaims](./22-pvc-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=ey5-3TGUCTc) |
| 23 | [StorageClass and dynamic provisioning](./23-storageclass-in-kuberbetes) | [Watch](https://www.youtube.com/watch?v=6PXMndb4oY0) |
| 24 | [ConfigMaps](./24-configmaps-kubernetes) | [Watch](https://www.youtube.com/watch?v=uKnlrU6kvc0) |
| 25 | [Secrets](./25-secrets-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=lqljr5wb15E) |

### Reliability and scaling

| # | Module | Video |
| :-: | :-- | :-- |
| 26 | [Probes: liveness, readiness and startup](./26-probes-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=DejT5ejknM4) |
| 27 | [Requests and limits: QoS and OOMKilled](./27-requests-limits-kubernetes) | [Watch](https://www.youtube.com/watch?v=1nAsxJSsfkw) |
| 28 | [Horizontal Pod Autoscaler (HPA)](./28-hpa-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=fgXRoLkyehQ) |
| 29 | [Vertical Pod Autoscaler (VPA)](./29-vpa-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=NFdaLu42PsI) |

### Security and scheduling

| # | Module | Video |
| :-: | :-- | :-- |
| 30 | [RBAC: Role, RoleBinding, ClusterRole and ClusterRoleBinding](./30-RBAC-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=CmabO5t75eM) |
| 31 | [Service accounts and tokens](./31-service-accounts-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=IajpsLD21RA) |
| 32 | [Taints and tolerations](./32-taints-and-tolerations-in-kubernetes) | [Watch](https://www.youtube.com/watch?v=yTLvgkQLNKU) |
| 33 | [Node affinity](./33-node-affinity-kubernetes) | [Watch](https://www.youtube.com/watch?v=L_mLCT8FW6c) |
| 34 | [Network policies](./34-network-policies-in-kubernetes) | Coming soon |

---

## 🤝 Contributing

Corrections and improvements are welcome:

- **Found a mistake** (a typo, a broken command or a manifest that no longer works on a current Kubernetes version)? [Open an issue](https://github.com/theshubhamgour/kubernetes-tutorial/issues) or send a pull request.
- **Want a topic covered?** Open an issue with the topic and why it matters to you.
- Keep pull requests small and focused on one module. Include the Kubernetes version you tested with.

## 💖 Support

If this course helped you, ⭐ **star the repository** so other learners can find it, and subscribe on [YouTube](https://www.youtube.com/@shubhamgourtech) for new modules.

---

<sub>Made with care for the DevOps community by [Shubham Gour](https://github.com/theshubhamgour) · [YouTube](https://www.youtube.com/@shubhamgourtech) · [Blog](https://theshubhamgour.hashnode.dev/) · [LinkedIn](https://www.linkedin.com/in/theshubhamgour/)</sub>
