#!/bin/bash
# Q7: NetworkPolicy deny all – development namespace with a deployment
set -e
echo "Setting up Q7: development namespace and deployment..."
kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment dev-app --image=nginx:alpine -n development --replicas=1 --dry-run=client -o yaml | kubectl apply -f -
echo "Q7 setup done: student creates NetworkPolicy deny-all-traffic in development"
exit 0
