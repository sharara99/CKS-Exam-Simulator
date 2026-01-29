#!/bin/bash
# CKS 2026 – Fast setup: creates all namespaces and K8s objects needed before solving questions
# Mirrors CKA 2025 approach: one script creates essential resources so the exam is ready to start

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
# Optional: space namespace for Ingress practice (from expect-exam)
# ---------------------------------------------------------------------------
kubectl create deployment rocket-server --image=nginx:alpine -n space --replicas=1 --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
kubectl expose deployment rocket-server --port=80 --target-port=80 -n space --name=rocket-server --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# ---------------------------------------------------------------------------
# Wait for deployments to be available (best effort)
# ---------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Waiting for deployments..."
for ns in immutable-app dual-container team-sedum development naboo qa team-coral code space; do
  for d in $(kubectl get deploy -n "$ns" -o name 2>/dev/null); do
    kubectl wait --for=condition=available --timeout=60s "$d" -n "$ns" 2>/dev/null || true
  done
done
# restricted web-server will stay 0/1 until student fixes PSS – that's expected
kubectl wait --for=condition=available --timeout=10s deployment/web-server -n restricted 2>/dev/null || true

echo "$(date '+%Y-%m-%d %H:%M:%S') | CKS 2026 setup completed."
echo "Namespaces: development, naboo, qa, team-sedum, team-coral, code, restricted, space, immutable-app, dual-container"
echo "Resources: app-to-secure, dual-app, one, two, dev-app, naboo-app, qa-app, stream-multiplex, code-server, web-server, rocket-server"
exit 0
