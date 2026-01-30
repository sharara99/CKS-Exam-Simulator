#!/bin/bash
# CKS 2026 – Fast setup: creates all namespaces and K8s objects needed before solving questions
# One script creates essential resources so the exam is ready to start
# 
# Note: q1_setup.sh creates all required paths and files on cluster nodes
# (etcd.yaml, kubelet config, webhook configs, audit logs, etc.)

set -e

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting CKS 2026 exam setup..."

# ---------------------------------------------------------------------------
# 1. Create all namespaces
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating namespaces..."
kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace naboo --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace qa --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace team-sedum --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace team-coral --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace code --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace restricted --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace space --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace immutable-app --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dual-container --dry-run=client -o yaml | kubectl apply -f -

# Namespace labels for NetworkPolicy / Pod Security
kubectl label namespace qa name=qa --overwrite
kubectl label namespace restricted pod-security.kubernetes.io/enforce=restricted --overwrite

# ---------------------------------------------------------------------------
# Q2: ClusterRoleBinding for anonymous access (student must remove it)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q2: anonymous ClusterRoleBinding..."
kubectl create clusterrolebinding anonymous-access --clusterrole=view --user=system:anonymous --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# ---------------------------------------------------------------------------
# Q4: Deployment that needs readOnlyRootFilesystem (student adds it)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q4: deployment for readOnlyRootFilesystem..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-to-secure
  namespace: immutable-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-to-secure
  template:
    metadata:
      labels:
        app: app-to-secure
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# ---------------------------------------------------------------------------
# Q5: Deployment with 2 containers (student adds security context)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q5: deployment with 2 containers..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dual-app
  namespace: dual-container
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dual-app
  template:
    metadata:
      labels:
        app: dual-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
      - name: sidecar
        image: busybox:stable
        command: ["sleep", "3600"]
EOF

# ---------------------------------------------------------------------------
# Q6: Istio – team-sedum with deployments one and two (student labels ns + rollout restart)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q6: team-sedum deployments one and two..."
kubectl create deployment one --image=nginx:alpine -n team-sedum --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment two --image=nginx:alpine -n team-sedum --dry-run=client -o yaml | kubectl apply -f -

# ---------------------------------------------------------------------------
# Q7: development – pods to apply deny-all NetworkPolicy (student creates policy)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q7: development deployment..."
kubectl create deployment dev-app --image=nginx:alpine -n development --replicas=1 --dry-run=client -o yaml | kubectl apply -f -

# ---------------------------------------------------------------------------
# Q8: naboo + qa – pods in naboo; qa namespace with label name=qa (student creates NetworkPolicy)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q8: naboo and qa deployments..."
kubectl create deployment naboo-app --image=nginx:alpine -n naboo --replicas=1 --dry-run=client -o yaml | kubectl apply -f -
cat <<'QAEOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qa-app
  namespace: qa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: qa-app
      environmental: stage
  template:
    metadata:
      labels:
        app: qa-app
        environmental: stage
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
QAEOF
# Pods in naboo allow from: namespace qa, OR pods with environmental=stage. Student creates policy in naboo.

# ---------------------------------------------------------------------------
# Q10: team-coral – ServiceAccount stream-multiplex + deployment stream-multiplex (student adds token mount)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q10: ServiceAccount and deployment stream-multiplex..."
kubectl create serviceaccount stream-multiplex -n team-coral --dry-run=client -o yaml | kubectl apply -f -
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stream-multiplex
  namespace: team-coral
spec:
  replicas: 2
  selector:
    matchLabels:
      id: stream-multiplex
  template:
    metadata:
      labels:
        id: stream-multiplex
    spec:
      containers:
      - name: httpd
        image: httpd:2-alpine
        resources:
          requests:
            cpu: 20m
            memory: 20Mi
        ports:
        - containerPort: 80
EOF

# ---------------------------------------------------------------------------
# Q11: code – deployment code-server (student creates TLS secret and mounts it)
# Note: TLS cert files need to be created on the node at /root/custom-cert.crt and /root/custom-key.key
# This is handled by q11_setup.sh which creates a job to generate them
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q11: code-server deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-server
  namespace: code
spec:
  replicas: 1
  selector:
    matchLabels:
      app: code-server
  template:
    metadata:
      labels:
        app: code-server
    spec:
      containers:
      - name: server
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# ---------------------------------------------------------------------------
# Q13: Falco – deployment that uses /dev/x folder (student finds and scales to zero)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q13: dev-x-app deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-x-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dev-x-app
  template:
    metadata:
      labels:
        app: dev-x-app
    spec:
      containers:
      - name: app
        image: busybox:stable
        command: ["sleep", "3600"]
        volumeMounts:
        - name: dev-x
          mountPath: /dev/x
      volumes:
      - name: dev-x
        hostPath:
          path: /dev/x
          type: DirectoryOrCreate
EOF

# ---------------------------------------------------------------------------
# Q3 & Q14: ImagePolicyWebhook – webhook server deployment
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q3/Q14: ImagePolicyWebhook webhook server..."
kubectl create namespace team-white --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls tls-image-bouncer-webhook \
  --cert=/dev/null \
  --key=/dev/null \
  -n team-white \
  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: image-bouncer-webhook
  name: image-bouncer-webhook
  namespace: team-white
spec:
  type: NodePort
  ports:
  - name: https
    port: 443
    targetPort: 1323
    protocol: TCP
    nodePort: 30080
  selector:
    app: image-bouncer-webhook
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-bouncer-webhook
  namespace: team-white
spec:
  selector:
    matchLabels:
      app: image-bouncer-webhook
  template:
    metadata:
      labels:
        app: image-bouncer-webhook
    spec:
      containers:
      - name: image-bouncer-webhook
        imagePullPolicy: Always
        image: "kainlite/kube-image-bouncer:latest"
        args:
        - "--cert=/etc/admission-controller/tls/tls.crt"
        - "--key=/etc/admission-controller/tls/tls.key"
        - "--debug"
        - "--registry-whitelist=docker.io,registry.k8s.io"
        volumeMounts:
        - name: tls
          mountPath: /etc/admission-controller/tls
      volumes:
      - name: tls
        secret:
          secretName: tls-image-bouncer-webhook
EOF

# ---------------------------------------------------------------------------
# Q15: restricted – deployment web-server that violates restricted PSS (student fixes)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q15: web-server in restricted namespace (violates PSS)..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
  namespace: restricted
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-server
  template:
    metadata:
      labels:
        app: web-server
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        securityContext:
          runAsUser: 0
        ports:
        - containerPort: 80
EOF

# ---------------------------------------------------------------------------
# Q16: Audit Log Policy – audit policy file and log directory (created via DaemonSet in q16_setup.sh)
# Note: q16_setup.sh creates files on control plane node
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Q16: Audit policy setup (run q16_setup.sh for file creation on nodes)..."

# ---------------------------------------------------------------------------
# Q17: Dockerfile / Deployment Best Practices – deployment with privileged and Dockerfile
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q17: insecure-app deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: insecure-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: insecure-app
  template:
    metadata:
      labels:
        app: insecure-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        securityContext:
          privileged: true
          # capabilities.drop is empty (student needs to add ["ALL"])
        ports:
        - containerPort: 80
EOF
# Dockerfile created via DaemonSet in q17_setup.sh

# ---------------------------------------------------------------------------
# Q18: Image Scan with Trivy – deployment with 3 containers + 5 pods with vulnerable images
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating Q18: multi-container deployment and vulnerable pods..."
# Deployment with 3 containers
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-container-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multi-container-app
  template:
    metadata:
      labels:
        app: multi-container-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
      - name: redis
        image: redis:6.2-alpine
        ports:
        - containerPort: 6379
      - name: app
        image: node:16-alpine
        command: ["sleep", "3600"]
EOF

# 5 pods with vulnerable images (student scans and deletes 3, keeps 2)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx3
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:3
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx37
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:3.7
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-photon3
  namespace: default
spec:
  containers:
  - name: photon
    image: photon:3.0
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-amazon
  namespace: default
spec:
  containers:
  - name: amazon
    image: amazonlinux:1
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-safe-alpine
  namespace: default
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sleep", "3600"]
EOF

# ---------------------------------------------------------------------------
# Q19: Create Ingress – service rocket-server (already created above)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Q19: Service rocket-server ready (student creates TLS secret and Ingress)..."

# ---------------------------------------------------------------------------
# Wait for deployments to be available (best effort)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Waiting for deployments..."
for ns in immutable-app dual-container team-sedum development naboo qa team-coral code space team-white; do
  for d in $(kubectl get deploy -n "$ns" -o name 2>/dev/null); do
    kubectl wait --for=condition=available --timeout=60s "$d" -n "$ns" 2>/dev/null || true
  done
done
# restricted web-server will stay 0/1 until student fixes PSS – that's expected
kubectl wait --for=condition=available --timeout=10s deployment/web-server -n restricted 2>/dev/null || true
# dev-x-app in default namespace
kubectl wait --for=condition=available --timeout=60s deployment/dev-x-app -n default 2>/dev/null || true

echo "$(date '+%Y-%m-%d %H:%M:%S') | CKS 2026 setup completed."
echo "Namespaces: development, naboo, qa, team-sedum, team-coral, code, restricted, space, immutable-app, dual-container, team-white"
echo "Resources: app-to-secure, dual-app, one, two, dev-app, naboo-app, qa-app, stream-multiplex, code-server, web-server, rocket-server, dev-x-app, image-bouncer-webhook, insecure-app, multi-container-app, pod-nginx3, pod-nginx37, pod-photon3, pod-amazon, pod-safe-alpine"
echo ""
echo "Note: For Q16, Q17, Q18, Q19 - run individual setup scripts if needed:"
echo "  - q16_setup.sh: Creates audit policy files on control plane node"
echo "  - q17_setup.sh: Creates Dockerfile directory"
echo "  - q18_setup.sh: Ensures all pods are created (if images fail to pull)"
echo "  - q19_setup.sh: Ensures service is ready"
exit 0
