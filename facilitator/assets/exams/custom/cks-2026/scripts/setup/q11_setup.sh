#!/bin/bash
# Q11: TLS secret mount – code namespace, deployment code-server (student creates secret and mounts)
set -e
echo "Setting up Q11: code namespace and deployment code-server..."
kubectl create namespace code --dry-run=client -o yaml | kubectl apply -f -
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
echo "Q11 setup done: student creates TLS secret and adds volume/volumeMount to code-server"
exit 0
