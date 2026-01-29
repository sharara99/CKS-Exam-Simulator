#!/bin/bash
# Q10: ServiceAccount token – team-coral, SA stream-multiplex, deployment stream-multiplex
set -e
echo "Setting up Q10: team-coral, ServiceAccount stream-multiplex, deployment stream-multiplex..."
kubectl create namespace team-coral --dry-run=client -o yaml | kubectl apply -f -
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
echo "Q10 setup done: student adds token-lifetime annotation, serviceAccountName, automountServiceAccountToken: false, projected volume"
exit 0
