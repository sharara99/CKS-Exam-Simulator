#!/bin/bash
# Q1: Create all required paths and files on cluster nodes
# This script creates paths and files needed for various CKS exam questions
# Uses a privileged DaemonSet to create files on all nodes

set -e
echo "Setting up Q1: Creating required paths and files on cluster nodes..."

# Create a DaemonSet that will create all required paths and files on each node
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: create-exam-paths-q1
  namespace: default
spec:
  selector:
    matchLabels:
      app: create-exam-paths-q1
  template:
    metadata:
      labels:
        app: create-exam-paths-q1
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: create-paths
        image: alpine:latest
        securityContext:
          privileged: true
        command:
        - sh
        - -c
        - |
          apk add --no-cache openssl
          
          # 1. Create kubelet config directory and file
          mkdir -p /hostroot/var/lib/kubelet
          if [ ! -f /hostroot/var/lib/kubelet/config.yaml ]; then
            cat > /hostroot/var/lib/kubelet/config.yaml <<'KUBELETEOF'
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
          mkdir -p /hostroot/etc/kubernetes/manifests
          if [ ! -f /hostroot/etc/kubernetes/manifests/etcd.yaml ]; then
            cat > /hostroot/etc/kubernetes/manifests/etcd.yaml <<'ETCDEOF'
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
          
          # 3. Create TLS certificates for code-secret (if not already created by q11)
          mkdir -p /hostroot/root
          if [ ! -f /hostroot/root/custom-cert.crt ]; then
            openssl req -x509 -newkey rsa:4096 -keyout /hostroot/root/custom-key.key -out /hostroot/root/custom-cert.crt -days 365 -nodes -subj "/CN=code-server" 2>/dev/null || {
              touch /hostroot/root/custom-cert.crt
              touch /hostroot/root/custom-key.key
              echo "Created placeholder certificate files"
            }
            chmod 600 /hostroot/root/custom-key.key 2>/dev/null || true
            chmod 644 /hostroot/root/custom-cert.crt 2>/dev/null || true
            echo "Created /root/custom-cert.crt and /root/custom-key.key"
          fi
          
          # 4. Create Image Policy Webhook directories and files
          mkdir -p /hostroot/opt/course/12/webhook
          mkdir -p /hostroot/etc/kubernetes/pki
          
          # AdmissionConfiguration file
          if [ ! -f /hostroot/opt/course/12/webhook/admission-config.yaml ]; then
            cat > /hostroot/opt/course/12/webhook/admission-config.yaml <<'ADMISSIONEOF'
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
          if [ ! -f /hostroot/opt/course/12/webhook/webhook.yaml ]; then
            cat > /hostroot/opt/course/12/webhook/webhook.yaml <<'WEBHOOKEOF'
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
          if [ ! -f /hostroot/opt/course/12/webhook/webhook-backend.crt ]; then
            openssl req -x509 -newkey rsa:4096 -keyout /hostroot/opt/course/12/webhook/webhook-backend.key -out /hostroot/opt/course/12/webhook/webhook-backend.crt -days 365 -nodes -subj "/CN=webhook-backend" 2>/dev/null || {
              touch /hostroot/opt/course/12/webhook/webhook-backend.crt
              echo "Created placeholder webhook-backend.crt"
            }
            echo "Created /opt/course/12/webhook/webhook-backend.crt"
          fi
          
          # AdmissionConfiguration in /etc/kubernetes/pki
          if [ ! -f /hostroot/etc/kubernetes/pki/admission_configuration.yaml ]; then
            cat > /hostroot/etc/kubernetes/pki/admission_configuration.yaml <<'PKIADMISSIONEOF'
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
          if [ ! -f /hostroot/etc/kubernetes/pki/admission_kube_config.yaml ]; then
            cat > /hostroot/etc/kubernetes/pki/admission_kube_config.yaml <<'PKIKUBECONFIGEOF'
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
          mkdir -p /hostroot/etc/kubernetes/audit/logs
          if [ ! -f /hostroot/etc/kubernetes/audit/policy.yaml ]; then
            cat > /hostroot/etc/kubernetes/audit/policy.yaml <<'AUDITEOF'
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
          if [ ! -f /hostroot/etc/kubernetes/audit/logs/audit.log ]; then
            touch /hostroot/etc/kubernetes/audit/logs/audit.log
            chmod 644 /hostroot/etc/kubernetes/audit/logs/audit.log 2>/dev/null || true
            echo "Created /etc/kubernetes/audit/logs/audit.log"
          fi
          
          # 6. Create Docker daemon.json
          mkdir -p /hostroot/etc/docker
          if [ ! -f /hostroot/etc/docker/daemon.json ]; then
            cat > /hostroot/etc/docker/daemon.json <<'DOCKEREOF'
{
  "hosts": ["unix:///var/run/docker.sock"]
}
DOCKEREOF
            echo "Created /etc/docker/daemon.json"
          fi
          
          # 7. Create Falco rules file
          mkdir -p /hostroot/etc/falco
          if [ ! -f /hostroot/etc/falco/falco_rules.local.yaml ]; then
            cat > /hostroot/etc/falco/falco_rules.local.yaml <<'FALCOEOF'
- rule: Custom Rule 1
  desc: Custom Rule 1
  condition: container and fd.name startswith /dev/x
  output: custom_rule_1 file=%fd.name container=%container.id
  priority: WARNING
FALCOEOF
            echo "Created /etc/falco/falco_rules.local.yaml"
          fi
          
          # 8. Create /dev/x directory for Falco testing
          mkdir -p /hostroot/dev/x
          echo "Created /dev/x directory"
          
          # 9. Create /opt/course/4 directory for stream-multiplex.yaml reference
          mkdir -p /hostroot/opt/course/4
          if [ ! -f /hostroot/opt/course/4/stream-multiplex.yaml ]; then
            cat > /hostroot/opt/course/4/stream-multiplex.yaml <<'STREAMEOF'
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
          sleep 3600
        volumeMounts:
        - name: hostroot
          mountPath: /hostroot
        - name: hostetc
          mountPath: /hostetc
        - name: hostvar
          mountPath: /hostvar
        - name: hostopt
          mountPath: /hostopt
        - name: hostdev
          mountPath: /hostdev
      volumes:
      - name: hostroot
        hostPath:
          path: /root
          type: DirectoryOrCreate
      - name: hostetc
        hostPath:
          path: /etc
          type: DirectoryOrCreate
      - name: hostvar
        hostPath:
          path: /var
          type: DirectoryOrCreate
      - name: hostopt
        hostPath:
          path: /opt
          type: DirectoryOrCreate
      - name: hostdev
        hostPath:
          path: /dev
          type: DirectoryOrCreate
EOF

echo "Q1 setup done: DaemonSet created to set up all required paths and files on cluster nodes"
echo "Paths created:"
echo "  - /var/lib/kubelet/config.yaml"
echo "  - /etc/kubernetes/manifests/etcd.yaml"
echo "  - /root/custom-cert.crt and /root/custom-key.key"
echo "  - /opt/course/12/webhook/*"
echo "  - /etc/kubernetes/pki/admission_*.yaml"
echo "  - /etc/kubernetes/audit/policy.yaml and /etc/kubernetes/audit/logs/audit.log"
echo "  - /etc/docker/daemon.json"
echo "  - /etc/falco/falco_rules.local.yaml"
echo "  - /dev/x directory"
echo "  - /opt/course/4/stream-multiplex.yaml"
exit 0
