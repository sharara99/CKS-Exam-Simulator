#!/bin/bash
# Q2: Remove Anonymous Access – create ClusterRoleBinding for anonymous (student must remove it)
set -e
echo "Setting up Q2: anonymous ClusterRoleBinding..."
kubectl create clusterrolebinding anonymous-access --clusterrole=view --user=system:anonymous --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
echo "Q2 setup done: student must remove ClusterRoleBinding anonymous-access"
exit 0
