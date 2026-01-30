# CKS 2026 Exam - Question Prerequisites

This document lists all resources that need to be created before solving each question.

## Summary

- **Q1-Q15**: Already set up in `fast_setup.sh`
- **Q16-Q19**: Added to `fast_setup.sh` and have individual setup scripts

---

## Detailed Prerequisites by Question

### Q1: CIS Benchmark – Kubelet
**Namespace**: `default`  
**Prerequisites**:
- ✅ Kubelet config file at `/var/lib/kubelet/config.yaml` (created by `q1_setup.sh`)
- ✅ etcd manifest at `/etc/kubernetes/manifests/etcd.yaml` (created by `q1_setup.sh`)
- ✅ Node/SSH access required

**Setup Script**: `q1_setup.sh`

---

### Q2: Remove Anonymous Access to API Server
**Namespace**: `default`  
**Prerequisites**:
- ✅ ClusterRoleBinding `anonymous-access` (created by `fast_setup.sh`)
- ✅ Node/SSH access to modify apiserver manifest

**Setup Script**: `q2_setup.sh`

---

### Q3: Image Policy Webhook
**Namespace**: `team-white`  
**Prerequisites**:
- ✅ Namespace `team-white` (created by `fast_setup.sh`)
- ✅ Webhook server deployment `image-bouncer-webhook` (created by `fast_setup.sh`)
- ✅ Webhook service `image-bouncer-webhook` (NodePort 30080) (created by `fast_setup.sh`)
- ✅ Webhook config files (created by `q3_setup.sh`)
- ✅ Node/SSH access to modify apiserver manifest

**Setup Script**: `q3_setup.sh`

---

### Q4: Deployment – readOnlyRootFilesystem
**Namespace**: `immutable-app`  
**Prerequisites**:
- ✅ Namespace `immutable-app` (created by `fast_setup.sh`)
- ✅ Deployment `app-to-secure` (created by `fast_setup.sh`)

**Setup Script**: `q4_setup.sh`

---

### Q5: Deployment – Security Context (2 containers)
**Namespace**: `dual-container`  
**Prerequisites**:
- ✅ Namespace `dual-container` (created by `fast_setup.sh`)
- ✅ Deployment `dual-app` with 2 containers (created by `fast_setup.sh`)

**Setup Script**: `q5_setup.sh`

---

### Q6: Istio Sidecar Injection
**Namespace**: `team-sedum`  
**Prerequisites**:
- ✅ Namespace `team-sedum` (created by `fast_setup.sh`)
- ✅ Deployment `one` (created by `fast_setup.sh`)
- ✅ Deployment `two` (created by `fast_setup.sh`)
- ✅ Istio must be installed in cluster

**Setup Script**: `q6_setup.sh`

---

### Q7: NetworkPolicy – Deny All Traffic
**Namespace**: `development`  
**Prerequisites**:
- ✅ Namespace `development` (created by `fast_setup.sh`)
- ✅ Deployment `dev-app` (created by `fast_setup.sh`)

**Setup Script**: `q7_setup.sh`

---

### Q8: NetworkPolicy – Allow from Stage and QA
**Namespace**: `naboo`, `qa`  
**Prerequisites**:
- ✅ Namespace `naboo` (created by `fast_setup.sh`)
- ✅ Namespace `qa` with label `name=qa` (created by `fast_setup.sh`)
- ✅ Deployment `naboo-app` in `naboo` (created by `fast_setup.sh`)
- ✅ Deployment `qa-app` with label `environmental: stage` in `qa` (created by `fast_setup.sh`)

**Setup Script**: `q8_setup.sh`

---

### Q9: Upgrade Kubernetes
**Namespace**: `default`  
**Prerequisites**:
- ✅ Cluster nodes (no specific resources needed)
- ✅ Node/SSH access required

**Setup Script**: None (cluster-level operation)

---

### Q10: ServiceAccount Token Expiration
**Namespace**: `team-coral`  
**Prerequisites**:
- ✅ Namespace `team-coral` (created by `fast_setup.sh`)
- ✅ ServiceAccount `stream-multiplex` (created by `fast_setup.sh`)
- ✅ Deployment `stream-multiplex` (created by `fast_setup.sh`)

**Setup Script**: `q10_setup.sh`

---

### Q11: TLS Secret – Create and Mount
**Namespace**: `code`  
**Prerequisites**:
- ✅ Namespace `code` (created by `fast_setup.sh`)
- ✅ Deployment `code-server` (created by `fast_setup.sh`)
- ✅ TLS certificate files at `/root/custom-cert.crt` and `/root/custom-key.key` (created by `q11_setup.sh`)

**Setup Script**: `q11_setup.sh`

---

### Q12: Docker Security
**Namespace**: `default`  
**Prerequisites**:
- ✅ Node/SSH access required
- ✅ Docker installed and running
- ✅ User in docker group (student removes)

**Setup Script**: None (node-level configuration)

---

### Q13: Falco – Custom Rule and Scale to Zero
**Namespace**: `default`  
**Prerequisites**:
- ✅ Deployment `dev-x-app` with volume mount `/dev/x` (created by `fast_setup.sh`)
- ✅ Falco installed in cluster

**Setup Script**: `q13_setup.sh`

---

### Q14: ImagePolicyWebhook – AdmissionConfiguration
**Namespace**: `team-white`  
**Prerequisites**:
- ✅ Namespace `team-white` (created by `fast_setup.sh`)
- ✅ Webhook server deployment `image-bouncer-webhook` (created by `fast_setup.sh`)
- ✅ Webhook config directory `/opt/course/12/webhook/` (created by `q14_setup.sh`)
- ✅ Node/SSH access to modify apiserver manifest

**Setup Script**: `q14_setup.sh`

---

### Q15: Pod Security Standard – Restricted
**Namespace**: `restricted`  
**Prerequisites**:
- ✅ Namespace `restricted` with label `pod-security.kubernetes.io/enforce=restricted` (created by `fast_setup.sh`)
- ✅ Deployment `web-server` with `runAsUser: 0` (violates PSS) (created by `fast_setup.sh`)

**Setup Script**: `q15_setup.sh`

---

### Q16: Audit Log Policy ⚠️ NEW
**Namespace**: `default`  
**Prerequisites**:
- ✅ Audit policy file at `/etc/kubernetes/audit/policy.yaml` (created by `q16_setup.sh`)
- ✅ Audit log directory at `/etc/kubernetes/audit/logs/` (created by `q16_setup.sh`)
- ✅ Audit log file at `/etc/kubernetes/audit/logs/audit.log` (created by `q16_setup.sh`)
- ✅ Node/SSH access to control plane node

**Setup Script**: `q16_setup.sh` (creates files on control plane node via DaemonSet)

---

### Q17: Dockerfile / Deployment Best Practices ⚠️ NEW
**Namespace**: `default`  
**Prerequisites**:
- ✅ Deployment `insecure-app` with `privileged: true` and empty `capabilities.drop` (created by `fast_setup.sh`)
- ✅ Dockerfile at `/opt/course/17/dockerfile/Dockerfile` (uses `latest` tag, runs as root) (created by `q17_setup.sh`)

**Setup Script**: `q17_setup.sh`

---

### Q18: Image Scan with Trivy ⚠️ NEW
**Namespace**: `default`  
**Prerequisites**:
- ✅ Deployment `multi-container-app` with 3 containers (created by `fast_setup.sh`)
- ✅ Pod `pod-nginx3` with image `nginx:3` (vulnerable) (created by `fast_setup.sh`)
- ✅ Pod `pod-nginx37` with image `nginx:3.7` (vulnerable) (created by `fast_setup.sh`)
- ✅ Pod `pod-photon3` with image `photon:3.0` (vulnerable) (created by `fast_setup.sh`)
- ✅ Pod `pod-amazon` with image `amazonlinux:1` (vulnerable) (created by `fast_setup.sh`)
- ✅ Pod `pod-safe-alpine` with image `alpine:latest` (safe) (created by `fast_setup.sh`)
- ✅ Trivy installed (student may need to install)

**Setup Script**: `q18_setup.sh`

**Note**: Student should scan all pods, extract to YAML files, and delete pods with Critical/High vulnerabilities (should delete 3, keep 2).

---

### Q19: Create Ingress ⚠️ NEW
**Namespace**: `space`  
**Prerequisites**:
- ✅ Namespace `space` (created by `fast_setup.sh`)
- ✅ Deployment `rocket-server` (created by `fast_setup.sh`)
- ✅ Service `rocket-server` on port 80 (created by `fast_setup.sh`)
- ⚠️ TLS secret `rocket-tls` (student creates)
- ⚠️ Ingress resource (student creates)
- ✅ nginx Ingress Controller installed

**Setup Script**: `q19_setup.sh`

---

## Running Setup Scripts

### Option 1: Fast Setup (Recommended)
Run `fast_setup.sh` to create all resources at once:
```bash
./scripts/setup/fast_setup.sh
```

### Option 2: Individual Setup Scripts
Run individual setup scripts for specific questions:
```bash
./scripts/setup/q1_setup.sh
./scripts/setup/q2_setup.sh
# ... etc
```

### Option 3: Node-Level Setup
Some questions require files on cluster nodes. These are created via DaemonSets:
- Q1: Kubelet config, etcd manifest
- Q11: TLS certificate files
- Q16: Audit policy files
- Q17: Dockerfile

---

## Notes

1. **Node Access**: Questions 1, 2, 3, 9, 12, 14, 16 require SSH/node access to modify cluster components
2. **Image Pulling**: Some images in Q18 might not exist or fail to pull. In a real exam, images would be pre-pulled.
3. **Istio**: Q6 requires Istio to be installed in the cluster
4. **Falco**: Q13 requires Falco to be installed
5. **Trivy**: Q18 requires Trivy to be installed (student may need to install it)
6. **Ingress Controller**: Q19 requires nginx Ingress Controller to be installed

---

## Verification

After running setup scripts, verify resources:
```bash
# Check namespaces
kubectl get namespaces

# Check deployments
kubectl get deployments --all-namespaces

# Check pods
kubectl get pods --all-namespaces

# Check services
kubectl get services --all-namespaces
```
