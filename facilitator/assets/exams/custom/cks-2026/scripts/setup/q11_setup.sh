#!/bin/bash
# Q11: TLS secret mount – code namespace, deployment code-server (student creates secret and mounts)
# Also creates TLS certificate files on the node for student to use
set -e
echo "Setting up Q11: code namespace, deployment code-server, and TLS cert files..."

# Create namespace and deployment (idempotent)
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

# Create TLS certificate files on the node using a privileged DaemonSet
# This will create certs on each node at /root/custom-cert.crt and /root/custom-key.key
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: create-tls-certs-q11
  namespace: default
spec:
  selector:
    matchLabels:
      app: create-tls-certs-q11
  template:
    metadata:
      labels:
        app: create-tls-certs-q11
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: create-certs
        image: alpine:latest
        securityContext:
          privileged: true
        command:
        - sh
        - -c
        - |
          apk add --no-cache openssl
          # Create self-signed certificate and key on the host
          openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /hostroot/custom-key.key \
            -out /hostroot/custom-cert.crt \
            -subj "/CN=code-server/O=code" 2>/dev/null || true
          chmod 644 /hostroot/custom-cert.crt 2>/dev/null || true
          chmod 600 /hostroot/custom-key.key 2>/dev/null || true
          echo "TLS certificates created at /root/custom-cert.crt and /root/custom-key.key"
          sleep 3600
        volumeMounts:
        - name: hostroot
          mountPath: /hostroot
      volumes:
      - name: hostroot
        hostPath:
          path: /root
          type: DirectoryOrCreate
EOF

echo "Q11 setup done: code-server deployment created. TLS cert files created on node at /root/custom-cert.crt and /root/custom-key.key"
exit 0
