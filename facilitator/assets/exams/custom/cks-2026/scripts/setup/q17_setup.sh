#!/bin/bash
# Q17: Dockerfile / Deployment Best Practices
# Create deployment with privileged: true and empty capabilities.drop
# Create a Dockerfile that needs to be fixed (uses latest tag, runs as root)
set -e
echo "Setting up Q17: Deployment with privileged and Dockerfile..."

# Create namespace if needed
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

# Create deployment with privileged: true and empty capabilities.drop (student fixes this)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: insecure-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: insecure-app
  template:
    metadata:
      labels:
        app: insecure-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        securityContext:
          privileged: true
          # capabilities.drop is empty (student needs to add ["ALL"])
        ports:
        - containerPort: 80
EOF

# Create a Dockerfile directory and file on a node (student needs to fix Dockerfile)
# Create it using a DaemonSet that writes to /opt/course/17/dockerfile/
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: create-dockerfile-q17
  namespace: default
spec:
  selector:
    matchLabels:
      app: create-dockerfile-q17
  template:
    metadata:
      labels:
        app: create-dockerfile-q17
    spec:
      hostNetwork: true
      containers:
      - name: create-files
        image: alpine:latest
        securityContext:
          privileged: true
        command:
        - sh
        - -c
        - |
          mkdir -p /host/opt/course/17/dockerfile
          
          # Create Dockerfile that needs fixing (uses latest, runs as root)
          cat > /host/opt/course/17/dockerfile/Dockerfile <<'DOCKEREOF'
FROM nginx:latest
RUN apt-get update && apt-get install -y curl
RUN echo "Hello World" > /usr/share/nginx/html/index.html
# Missing: USER nobody (should be added at the end)
DOCKEREOF
          
          chmod 644 /host/opt/course/17/dockerfile/Dockerfile
          echo "Dockerfile created at /opt/course/17/dockerfile/Dockerfile"
          sleep 3600
        volumeMounts:
        - name: hostopt
          mountPath: /host/opt
      volumes:
      - name: hostopt
        hostPath:
          path: /opt
          type: DirectoryOrCreate
EOF

echo "Q17 setup done:"
echo "  - Deployment 'insecure-app' created with privileged: true (student fixes to false and adds capabilities.drop: [\"ALL\"])"
echo "  - Dockerfile created at /opt/course/17/dockerfile/Dockerfile (student fixes: add version tag, add USER nobody)"
exit 0
