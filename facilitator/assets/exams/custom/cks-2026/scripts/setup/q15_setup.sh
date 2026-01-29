#!/bin/bash
# Q15: Pod Security restricted – namespace restricted with web-server that violates PSS (student fixes)
set -e
echo "Setting up Q15: restricted namespace and web-server deployment (violates restricted PSS)..."
kubectl create namespace restricted --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace restricted pod-security.kubernetes.io/enforce=restricted --overwrite
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
echo "Q15 setup done: student fixes deployment (allowPrivilegeEscalation: false, capabilities.drop: ALL, runAsNonRoot: true, seccompProfile, remove runAsUser: 0)"
exit 0
