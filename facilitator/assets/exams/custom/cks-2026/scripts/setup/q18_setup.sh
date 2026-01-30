#!/bin/bash
# Q18: Image Scan with Trivy
# Task 1: Deployment with 3 containers (one has library x with version y)
# Task 2: 5 pods total with images: nginx:3, nginx:3.7, photon:3, amazon, and one safe image
# Student scans and removes pods with Critical/High vulnerabilities (should delete 3, keep 2)
set -e
echo "Setting up Q18: Pods with vulnerable images for Trivy scanning..."

# Create namespace if needed
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

# Task 1: Deployment with 3 containers (one has a specific library version)
# Using a multi-container deployment where one container has a vulnerable library
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-container-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multi-container-app
  template:
    metadata:
      labels:
        app: multi-container-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
      - name: redis
        image: redis:6.2-alpine
        ports:
        - containerPort: 6379
      - name: app
        # This image might have a vulnerable library - student needs to scan it
        image: node:16-alpine
        command: ["sleep", "3600"]
EOF

# Task 2: Create 5 pods with vulnerable images
# Pods with nginx:1.18, nginx:1.19, photon:3.0, amazon (these have vulnerabilities)
# Note: Original question mentions nginx:3 and nginx:3.7, but these don't exist.
#       Using nginx:1.18 and nginx:1.19 instead (older versions with vulnerabilities).
#       photon:3 doesn't exist, using photon:3.0 (correct tag).
# Plus one safe pod (alpine) - student should keep 2 safe ones

# Pod 1: nginx:1.18 (older version with vulnerabilities - should be deleted)
# Note: nginx:3 doesn't exist, using nginx:1.18 which has known vulnerabilities
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx3
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.18
    ports:
    - containerPort: 80
EOF

# Pod 2: nginx:1.19 (older version with vulnerabilities - should be deleted)
# Note: nginx:3.7 doesn't exist, using nginx:1.19 which has known vulnerabilities
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx37
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.19
    ports:
    - containerPort: 80
EOF

# Pod 3: photon:3.0 (vulnerable - should be deleted)
# Note: photon:3 doesn't exist, using photon:3.0 which is the correct tag
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-photon3
  namespace: default
spec:
  containers:
  - name: photon
    image: photon:3.0
    command: ["sleep", "3600"]
EOF

# Pod 4: amazon image (vulnerable - should be deleted)
# Using amazonlinux:1 which is known to have vulnerabilities
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-amazon
  namespace: default
spec:
  containers:
  - name: amazon
    image: amazonlinux:1
    command: ["sleep", "3600"]
EOF

# Pod 5: Safe pod (alpine - should be kept)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-safe-alpine
  namespace: default
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sleep", "3600"]
EOF

# Note: Some of these images might not exist or pull. In real exam, they would be pre-pulled.
# For the simulator, we use images that exist but may have vulnerabilities when scanned.
# Student should scan all pods and delete the ones with Critical/High vulnerabilities.

echo "Q18 setup done:"
echo "  - Deployment 'multi-container-app' with 3 containers created (student scans one image for SBOM)"
echo "  - 5 pods created:"
echo "    * pod-nginx3 (nginx:1.18) - older version, likely vulnerable"
echo "    * pod-nginx37 (nginx:1.19) - older version, likely vulnerable"
echo "    * pod-photon3 (photon:3.0) - likely vulnerable"
echo "    * pod-amazon (amazonlinux:1) - likely vulnerable"
echo "    * pod-safe-alpine (alpine:latest) - should be safe"
echo ""
echo "Note: Original question mentions nginx:3 and nginx:3.7, but these don't exist."
echo "      Using nginx:1.18 and nginx:1.19 instead (older versions with vulnerabilities)."
echo "      photon:3 doesn't exist, using photon:3.0 (correct tag)."
echo "  Student should:"
echo "    1. Extract all pods to YAML files"
echo "    2. Scan images with Trivy"
echo "    3. Delete pods with Critical/High vulnerabilities (should delete 3, keep 2)"
exit 0
