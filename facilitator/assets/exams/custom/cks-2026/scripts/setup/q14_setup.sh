#!/bin/bash
# Q14: ImagePolicyWebhook – AdmissionConfiguration (student creates config files and mounts in apiserver)
set -e
echo "Setting up Q14: ImagePolicyWebhook AdmissionConfiguration resources..."

# Create namespace for webhook
kubectl create namespace team-white --dry-run=client -o yaml | kubectl apply -f -

# Create ImagePolicyWebhook deployment and service (same as Q3)
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

# Create TLS secret for webhook
kubectl create secret tls tls-image-bouncer-webhook \
  --cert=/dev/null \
  --key=/dev/null \
  -n team-white \
  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Note: Student will create AdmissionConfiguration and kubeconfig files at /opt/course/12/webhook/
# and configure apiserver to mount and use them

echo "Q14 setup done: ImagePolicyWebhook webhook server deployed. Student creates AdmissionConfiguration and configures apiserver."
exit 0
