#!/bin/bash
# Q3: ImagePolicyWebhook – Create webhook deployment and service (student configures apiserver)
set -e
echo "Setting up Q3: ImagePolicyWebhook webhook server..."

# Create namespace for webhook if needed
kubectl create namespace team-white --dry-run=client -o yaml | kubectl apply -f -

# Create TLS secret for webhook (student may need to update this)
kubectl create secret tls tls-image-bouncer-webhook \
  --cert=/dev/null \
  --key=/dev/null \
  -n team-white \
  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create ImagePolicyWebhook deployment and service
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

echo "Q3 setup done: ImagePolicyWebhook webhook server deployed. Student configures apiserver to use it."
exit 0
