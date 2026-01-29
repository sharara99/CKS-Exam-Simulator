#!/bin/bash
# Q5: Deployment with 2 containers – student adds security context to each
set -e
echo "Setting up Q5: deployment dual-app with 2 containers..."
kubectl create namespace dual-container --dry-run=client -o yaml | kubectl apply -f -
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
echo "Q5 setup done: student adds runAsUser: 30000, allowPrivilegeEscalation: false, readOnlyRootFilesystem: true"
exit 0
