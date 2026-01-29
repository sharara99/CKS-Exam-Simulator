#!/bin/bash
# Q8: NetworkPolicy allow from stage and qa – naboo, qa namespaces and deployments
set -e
echo "Setting up Q8: naboo and qa namespaces with deployments..."
kubectl create namespace naboo --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace qa --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace qa name=qa --overwrite

kubectl create deployment naboo-app --image=nginx:alpine -n naboo --replicas=1 --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' | kubectl apply -f -
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
EOF
echo "Q8 setup done: student creates NetworkPolicy allow-from-stage-and-qa in naboo"
exit 0
