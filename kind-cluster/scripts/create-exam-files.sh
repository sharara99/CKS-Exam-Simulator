#!/bin/bash
# Script to create all required directories and files for CKS exam questions
# This script is executed during Docker build to pre-create exam files

set -e

echo "Creating required paths and files for CKS exam..."

# 1. Create kubelet config directory and file
mkdir -p /var/lib/kubelet
if [ ! -f /var/lib/kubelet/config.yaml ]; then
  cat > /var/lib/kubelet/config.yaml <<'KUBELETEOF'
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: true
authorization:
  mode: AlwaysAllow
KUBELETEOF
  echo "Created /var/lib/kubelet/config.yaml"
fi

# 2. Create etcd manifest file (CRITICAL - shown as missing in exam)
mkdir -p /etc/kubernetes/manifests
if [ ! -f /etc/kubernetes/manifests/etcd.yaml ]; then
  cat > /etc/kubernetes/manifests/etcd.yaml <<'ETCDEOF'
apiVersion: v1
kind: Pod
metadata:
  name: etcd
  namespace: kube-system
spec:
  containers:
  - name: etcd
    image: k8s.gcr.io/etcd:3.5.0-0
    command:
    - etcd
    - --name=etcd0
    - --data-dir=/var/lib/etcd
    - --listen-client-urls=http://127.0.0.1:2379
    - --advertise-client-urls=http://127.0.0.1:2379
    - --listen-peer-urls=http://127.0.0.1:2380
    - --initial-advertise-peer-urls=http://127.0.0.1:2380
    - --initial-cluster=etcd0=http://127.0.0.1:2380
    - --initial-cluster-token=etcd-cluster-1
    - --initial-cluster-state=new
    - --heartbeat-interval=1000
    - --election-timeout=5000
    volumeMounts:
    - name: etcd-data
      mountPath: /var/lib/etcd
  volumes:
  - name: etcd-data
    hostPath:
      path: /var/lib/etcd
      type: DirectoryOrCreate
ETCDEOF
  echo "Created /etc/kubernetes/manifests/etcd.yaml"
fi

# 3. Create TLS certificates for code-secret
mkdir -p /root
if [ ! -f /root/custom-cert.crt ]; then
  if command -v openssl &> /dev/null; then
    openssl req -x509 -newkey rsa:4096 -keyout /root/custom-key.key -out /root/custom-cert.crt -days 365 -nodes -subj "/CN=code-server" 2>/dev/null || {
      touch /root/custom-cert.crt
      touch /root/custom-key.key
      echo "Created placeholder certificate files"
    }
  else
    touch /root/custom-cert.crt
    touch /root/custom-key.key
    echo "Created placeholder certificate files (openssl not available)"
  fi
  chmod 600 /root/custom-key.key 2>/dev/null || true
  chmod 644 /root/custom-cert.crt 2>/dev/null || true
  echo "Created /root/custom-cert.crt and /root/custom-key.key"
fi

# 4. Create Image Policy Webhook directories and files
mkdir -p /opt/course/12/webhook
mkdir -p /etc/kubernetes/pki

# AdmissionConfiguration file
if [ ! -f /opt/course/12/webhook/admission-config.yaml ]; then
  cat > /opt/course/12/webhook/admission-config.yaml <<'ADMISSIONEOF'
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/webhook/webhook.yaml
      allowTTL: 10
      denyTTL: 10
      retryBackoff: 20
      defaultAllow: true
ADMISSIONEOF
  echo "Created /opt/course/12/webhook/admission-config.yaml"
fi

# Webhook kubeconfig file
if [ ! -f /opt/course/12/webhook/webhook.yaml ]; then
  cat > /opt/course/12/webhook/webhook.yaml <<'WEBHOOKEOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/webhook/webhook-backend.crt
    server: https://10.111.10.111
  name: webhook
contexts:
- context:
    cluster: webhook
    user: webhook-backend.team-white.svc
  name: webhook
current-context: webhook
users:
- name: webhook-backend.team-white.svc
  user:
    client-certificate: /etc/kubernetes/pki/apiserver.crt
    client-key: /etc/kubernetes/pki/apiserver.key
WEBHOOKEOF
  echo "Created /opt/course/12/webhook/webhook.yaml"
fi

# Webhook backend certificate (placeholder)
if [ ! -f /opt/course/12/webhook/webhook-backend.crt ]; then
  if command -v openssl &> /dev/null; then
    openssl req -x509 -newkey rsa:4096 -keyout /opt/course/12/webhook/webhook-backend.key -out /opt/course/12/webhook/webhook-backend.crt -days 365 -nodes -subj "/CN=webhook-backend" 2>/dev/null || {
      touch /opt/course/12/webhook/webhook-backend.crt
      echo "Created placeholder webhook-backend.crt"
    }
  else
    touch /opt/course/12/webhook/webhook-backend.crt
    echo "Created placeholder webhook-backend.crt"
  fi
  echo "Created /opt/course/12/webhook/webhook-backend.crt"
fi

# AdmissionConfiguration in /etc/kubernetes/pki
if [ ! -f /etc/kubernetes/pki/admission_configuration.yaml ]; then
  cat > /etc/kubernetes/pki/admission_configuration.yaml <<'PKIADMISSIONEOF'
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/pki/admission_kube_config.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
PKIADMISSIONEOF
  echo "Created /etc/kubernetes/pki/admission_configuration.yaml"
fi

# Admission kubeconfig file
if [ ! -f /etc/kubernetes/pki/admission_kube_config.yaml ]; then
  cat > /etc/kubernetes/pki/admission_kube_config.yaml <<'PKIKUBECONFIGEOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/pki/server.crt
    server: https://image-bouncer-webhook:30080/image_policy
  name: bouncer_webhook
contexts:
- context:
    cluster: bouncer_webhook
    user: api-server
  name: bouncer_validator
current-context: bouncer_validator
preferences: {}
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/pki/apiserver.crt
    client-key: /etc/kubernetes/pki/apiserver.key
PKIKUBECONFIGEOF
  echo "Created /etc/kubernetes/pki/admission_kube_config.yaml"
fi

# 5. Create audit log policy and logs directory
mkdir -p /etc/kubernetes/audit/logs
if [ ! -f /etc/kubernetes/audit/policy.yaml ]; then
  cat > /etc/kubernetes/audit/policy.yaml <<'AUDITEOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets"]
- level: RequestResponse
  users: ["system:nodes"]
  resources:
  - group: ""
    resources: ["nodes"]
- level: Request
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
    namespaces: ["default"]
- level: Metadata
AUDITEOF
  echo "Created /etc/kubernetes/audit/policy.yaml"
fi

# Create empty audit log file
if [ ! -f /etc/kubernetes/audit/logs/audit.log ]; then
  touch /etc/kubernetes/audit/logs/audit.log
  chmod 644 /etc/kubernetes/audit/logs/audit.log 2>/dev/null || true
  echo "Created /etc/kubernetes/audit/logs/audit.log"
fi

# 6. Create Docker daemon.json
mkdir -p /etc/docker
if [ ! -f /etc/docker/daemon.json ]; then
  cat > /etc/docker/daemon.json <<'DOCKEREOF'
{
  "hosts": ["unix:///var/run/docker.sock"]
}
DOCKEREOF
  echo "Created /etc/docker/daemon.json"
fi

# 7. Create Falco rules file
mkdir -p /etc/falco
if [ ! -f /etc/falco/falco_rules.local.yaml ]; then
  cat > /etc/falco/falco_rules.local.yaml <<'FALCOEOF'
- rule: Custom Rule 1
  desc: Custom Rule 1
  condition: container and fd.name startswith /dev/x
  output: custom_rule_1 file=%fd.name container=%container.id
  priority: WARNING
FALCOEOF
  echo "Created /etc/falco/falco_rules.local.yaml"
fi

# 8. Create /dev/x directory for Falco testing
mkdir -p /dev/x
echo "Created /dev/x directory"

# 9. Create /opt/course/4 directory for stream-multiplex.yaml reference
mkdir -p /opt/course/4
if [ ! -f /opt/course/4/stream-multiplex.yaml ]; then
  cat > /opt/course/4/stream-multiplex.yaml <<'STREAMEOF'
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
      serviceAccountName: stream-multiplex
      automountServiceAccountToken: false
      containers:
        - image: httpd:2-alpine
          name: httpd
          resources:
            requests:
              cpu: 20m
              memory: 20Mi
          volumeMounts:
            - name: token-volume
              mountPath: /var/run/secrets/custom
              readOnly: true
      volumes:
        - name: token-volume
          projected:
            sources:
              - serviceAccountToken:
                  path: token
                  expirationSeconds: 1200
STREAMEOF
  echo "Created /opt/course/4/stream-multiplex.yaml"
fi

echo "All required paths and files created successfully!"
