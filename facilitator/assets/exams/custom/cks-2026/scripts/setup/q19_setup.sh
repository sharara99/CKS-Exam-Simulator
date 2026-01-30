#!/bin/bash
# Q19: Create Ingress
# Service rocket-server already exists (from fast_setup.sh)
# Student needs to create TLS secret rocket-tls and Ingress resource
set -e
echo "Setting up Q19: Service rocket-server and preparing for Ingress creation..."

# Ensure namespace exists
kubectl create namespace space --dry-run=client -o yaml | kubectl apply -f -

# Ensure deployment and service exist (idempotent)
kubectl create deployment rocket-server --image=nginx:alpine -n space --replicas=1 --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment rocket-server --port=80 --target-port=80 -n space --name=rocket-server --dry-run=client -o yaml | kubectl apply -f -

# Wait for service to be ready
kubectl wait --for=condition=available --timeout=60s deployment/rocket-server -n space 2>/dev/null || true

# Note: Student needs to create:
# 1. TLS secret named 'rocket-tls' in namespace 'space'
# 2. Ingress resource with TLS configuration pointing to rocket-server service

echo "Q19 setup done:"
echo "  - Deployment 'rocket-server' created in namespace 'space'"
echo "  - Service 'rocket-server' created (port 80)"
echo "  Student needs to:"
echo "    1. Create TLS secret 'rocket-tls' in namespace 'space'"
echo "    2. Create Ingress resource with:"
echo "       - ingressClassName: nginx"
echo "       - TLS secret: rocket-tls"
echo "       - Host: rocket-server.local"
echo "       - Backend: rocket-server service on port 80"
exit 0
