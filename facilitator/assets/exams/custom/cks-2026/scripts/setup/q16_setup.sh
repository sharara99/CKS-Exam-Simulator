#!/bin/bash
# Q16: Audit Log Policy – create audit policy file and log directory on API server node
# Student needs to modify policy and configure apiserver to use it
set -e
echo "Setting up Q16: Audit policy files and directories..."

# Create audit policy directory and files on the API server node using a DaemonSet
# This will create the files on the control plane node
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: create-audit-files-q16
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: create-audit-files-q16
  template:
    metadata:
      labels:
        app: create-audit-files-q16
    spec:
      hostNetwork: true
      hostPID: true
      nodeSelector:
        node-role.kubernetes.io/control-plane: ""
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: create-files
        image: alpine:latest
        securityContext:
          privileged: true
        command:
        - sh
        - -c
        - |
          # Create audit directories
          mkdir -p /host/etc/kubernetes/audit/logs
          chmod 755 /host/etc/kubernetes/audit
          chmod 755 /host/etc/kubernetes/audit/logs
          
          # Create initial audit policy file (student will modify this)
          cat > /host/etc/kubernetes/audit/policy.yaml <<'POLICYEOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Default rule - log all metadata
  - level: Metadata
POLICYEOF
          
          # Create empty audit log file
          touch /host/etc/kubernetes/audit/logs/audit.log
          chmod 644 /host/etc/kubernetes/audit/logs/audit.log
          chmod 644 /host/etc/kubernetes/audit/policy.yaml
          
          echo "Audit policy created at /etc/kubernetes/audit/policy.yaml"
          echo "Audit log directory created at /etc/kubernetes/audit/logs/"
          sleep 3600
        volumeMounts:
        - name: hostetc
          mountPath: /host/etc
      volumes:
      - name: hostetc
        hostPath:
          path: /etc
          type: DirectoryOrCreate
EOF

echo "Q16 setup done: Audit policy file created at /etc/kubernetes/audit/policy.yaml and log directory at /etc/kubernetes/audit/logs/"
echo "Student needs to:"
echo "  1. Modify policy.yaml to log Secrets at Metadata, system:nodes at RequestResponse, others at Metadata"
echo "  2. Configure apiserver to mount policy and log files"
echo "  3. Set log rotation to keep only one backup"
echo "  4. Empty the audit.log file"
exit 0
