#!/bin/bash
# Q4: Deployment readOnlyRootFilesystem – create deployment without it (student adds securityContext)
set -e
echo "Setting up Q4: deployment app-to-secure in immutable-app..."
kubectl create namespace immutable-app --dry-run=client -o yaml | kubectl apply -f -
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
echo "Q4 setup done: student adds readOnlyRootFilesystem: true"
exit 0
