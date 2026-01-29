#!/bin/bash
# Q13: Falco – Create deployment that uses /dev/x folder (student finds it and scales to zero)
set -e
echo "Setting up Q13: Deployment that uses /dev/x folder for Falco..."

# Create a deployment that mounts /dev/x as a volume
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-x-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dev-x-app
  template:
    metadata:
      labels:
        app: dev-x-app
    spec:
      containers:
      - name: app
        image: busybox:stable
        command: ["sleep", "3600"]
        volumeMounts:
        - name: dev-x
          mountPath: /dev/x
      volumes:
      - name: dev-x
        hostPath:
          path: /dev/x
          type: DirectoryOrCreate
EOF

echo "Q13 setup done: dev-x-app deployment created that uses /dev/x folder"
exit 0
