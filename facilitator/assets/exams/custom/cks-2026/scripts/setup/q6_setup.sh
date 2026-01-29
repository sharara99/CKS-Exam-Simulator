#!/bin/bash
# Q6: Istio sidecar – team-sedum namespace with deployments one and two
set -e
echo "Setting up Q6: team-sedum with deployments one and two..."
kubectl create namespace team-sedum --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment one --image=nginx:alpine -n team-sedum --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment two --image=nginx:alpine -n team-sedum --dry-run=client -o yaml | kubectl apply -f -
echo "Q6 setup done: student labels ns istio-injection=enabled and rollout restart"
exit 0
