#!/bin/sh

# ===============================================================================
#   KIND Cluster Setup Entrypoint Script
#   Purpose: Initialize Docker and create Kind cluster
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== INITIALIZATION STARTED ====="
echo "$(date '+%Y-%m-%d %H:%M:%S') | Executing container startup script..."

# Execute current entrypoint script
if [ -f /usr/local/bin/startup.sh ]; then
    sh /usr/local/bin/startup.sh &
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Default startup script not found at /usr/local/bin/startup.sh"
fi

# ===============================================================================
#   Docker Readiness Check
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | Checking Docker service status..."
DOCKER_CHECK_COUNT=0

# Wait for docker to be ready
while ! docker ps; do   
    DOCKER_CHECK_COUNT=$((DOCKER_CHECK_COUNT+1))
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [WAITING] Docker service not ready yet... (attempt $DOCKER_CHECK_COUNT)"
    sleep 5
done

echo "$(date '+%Y-%m-%d %H:%M:%S') | [SUCCESS] Docker service is ready and operational"

#pull kindest/node image
# docker pull kindest/node:$KIND_DEFAULT_VERSION

#add user for ssh access
adduser -S -D -H -s /sbin/nologin -G sshd sshd

#start ssh service
/usr/sbin/sshd -D &

#install k3d (skip if already installed)
echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Checking k3d installation"
if ! command -v k3d &> /dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | k3d not found. Attempting installation..."
    TAG=v5.8.3 bash /usr/local/bin/k3d-install.sh
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | k3d already installed, skipping installation"
fi

# Pre-create k3d cluster for faster exam startup
echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Pre-creating k3d cluster for faster exam startup"
if ! k3d cluster list | grep -q "cluster"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating pre-configured k3d cluster..."
    
    # Generate optimized k3d config (use ckx-network so jumphost/remote-terminal can reach API)
    cat <<EOF > /tmp/k3d-config.yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: cluster
network: ckx-network
servers: 1
agents: 1
ports:
  - port: "6445:6443"
    nodeFilters:
      - loadbalancer
kubeAPI:
  host: "0.0.0.0"
  hostPort: "6445"
options:
  k3s:
    extraArgs:
      - arg: "--tls-san=k8s-api-server"
        nodeFilters:
          - server:*
      - arg: "--tls-san=127.0.0.1"
        nodeFilters:
          - server:*
      - arg: "--tls-san=localhost"
        nodeFilters:
          - server:*
EOF
    
    # Try to create cluster with retry logic
    for attempt in 1 2 3; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') | Attempt $attempt: Creating k3d cluster..."
        if k3d cluster create --config /tmp/k3d-config.yaml; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') | ✅ k3d cluster created successfully on attempt $attempt"
            break
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') | ❌ Attempt $attempt failed, cleaning up..."
            k3d cluster delete cluster 2>/dev/null || true
            docker network prune -f 2>/dev/null || true
            if [ $attempt -lt 3 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') | Waiting 5 seconds before retry..."
                sleep 5
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') | ❌ All attempts failed, trying simple cluster creation with TLS SAN and network..."
                k3d cluster create cluster --network ckx-network --port "6445:6443@loadbalancer" --kubeconfig-switch-context=false --k3s-arg '--tls-san=k8s-api-server@server:0'
            fi
        fi
    done
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ✅ Pre-configured k3d cluster created successfully"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | k3d cluster already exists, verifying configuration..."
    # Check if cluster has correct TLS SAN, if not, recreate it
    if ! k3d cluster get cluster 2>&1 | grep -q "k8s-api-server"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') | Cluster missing TLS SAN for k8s-api-server, recreating with proper configuration..."
        k3d cluster delete cluster 2>/dev/null || true
        k3d cluster create cluster --network ckx-network --port "6445:6443@loadbalancer" --kubeconfig-switch-context=false --k3s-arg '--tls-san=k8s-api-server@server:0'
    fi
    # Always update kubeconfig even if cluster already exists (in case it was updated)
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Updating kubeconfig for existing cluster..."
    k3d kubeconfig write cluster --kubeconfig-switch-context=false
fi

# Copy and fix kubeconfig to shared volume
echo "$(date '+%Y-%m-%d %H:%M:%S') | Copying kubeconfig to shared volume..."
mkdir -p /home/candidate/.kube
k3d kubeconfig write cluster --kubeconfig-switch-context=false
# Use Docker Compose service name (k8s-api-server) which is on ckx-network and accessible from jumphost
# The k3d loadbalancer port 6443 is mapped to host port 6445, accessible via service name
sed -i 's|server: https://[^[:space:]]*|server: https://k8s-api-server:6445|g' /home/candidate/.kube/config
# Remove certificate-authority-data if it exists (cannot use with insecure-skip-tls-verify)
sed -i '/certificate-authority-data:/d' /home/candidate/.kube/config
# Add insecure-skip-tls-verify for certificate issues (only if not already present)
if ! grep -q "insecure-skip-tls-verify" /home/candidate/.kube/config; then
    sed -i '/server: https:\/\/k8s-api-server:6445/a\    insecure-skip-tls-verify: true' /home/candidate/.kube/config
fi
cp /home/candidate/.kube/config /home/candidate/.kube/kubeconfig
echo "$(date '+%Y-%m-%d %H:%M:%S') | ✅ Kubeconfig copied and configured with k8s-api-server:6445 and insecure-skip-tls-verify"

# ===============================================================================
#   Download cri-dockerd package to /home/candidate/downloads
# ===============================================================================
echo "$(date '+%Y-%m-%d %H:%M:%S') | Downloading cri-dockerd package to /home/candidate/downloads..."
mkdir -p /home/candidate/downloads
CRI_DOCKERD_URL="https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9/cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb"
if wget -q --timeout=30 "${CRI_DOCKERD_URL}" -O /home/candidate/downloads/cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb 2>/dev/null; then
    chmod 644 /home/candidate/downloads/cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb
    chown candidate:candidate /home/candidate/downloads/cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ✅ cri-dockerd package downloaded successfully to /home/candidate/downloads/"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ⚠️  WARNING: Failed to download cri-dockerd package (will retry later if needed)"
fi

# ===============================================================================
#   CKS Exam Resources Setup
#   Note: CKS resources are created by exam setup scripts (fast_setup.sh, q*_setup.sh)
#   CKA resources are not needed for CKS exam
# ===============================================================================
echo "$(date '+%Y-%m-%d %H:%M:%S') | CKS exam resources will be created by exam setup scripts"

# ===============================================================================
#   Auto-open Exam Interface
# ===============================================================================
echo "$(date '+%Y-%m-%d %H:%M:%S') | 🚀 Auto-opening CKS exam interface..."
echo "$(date '+%Y-%m-%d %H:%M:%S') | 📋 Exam Environment Ready!"
echo "$(date '+%Y-%m-%d %H:%M:%S') | 🌐 Opening exam interface at: http://localhost:30080"
echo "$(date '+%Y-%m-%d %H:%M:%S') | 📝 Lab: CKS 2026 Exam | Difficulty: Hard"
echo "$(date '+%Y-%m-%d %H:%M:%S') | ✅ Kubernetes cluster ready for CKS exam"

# Create a simple HTML page to redirect to the exam
cat <<EOF > /tmp/exam-ready.html
<!DOCTYPE html>
<html>
<head>
    <title>CKS 2026 Exam Ready</title>
    <meta http-equiv="refresh" content="2;url=http://localhost:30080">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
        }
        .container {
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { color: #4CAF50; margin-bottom: 20px; }
        .status { font-size: 18px; margin: 20px 0; }
        .redirect { font-size: 14px; margin-top: 30px; opacity: 0.8; }
        .spinner {
            border: 4px solid rgba(255,255,255,0.3);
            border-radius: 50%;
            border-top: 4px solid #4CAF50;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 CKS 2026 Exam Environment Ready!</h1>
        <div class="spinner"></div>
        <div class="status">
            <p>✅ Kubernetes cluster is running</p>
            <p>✅ CKS exam environment configured</p>
            <p>✅ Security-focused resources ready</p>
            <p>✅ Exam questions will be loaded on exam start</p>
        </div>
        <div class="redirect">
            <p>Redirecting to exam interface in 2 seconds...</p>
            <p>If not redirected automatically, <a href="http://localhost:30080" style="color: #4CAF50;">click here</a></p>
        </div>
    </div>
</body>
</html>
EOF

# Start a simple HTTP server to serve the ready page
echo "$(date '+%Y-%m-%d %H:%M:%S') | 🌐 Starting exam ready notification server on port 8080..."
python3 -m http.server 8080 --directory /tmp &
HTTP_PID=$!

# Wait a moment for the server to start
sleep 2

# Try to open the exam interface (this will work if running in a desktop environment)
if command -v xdg-open >/dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | 🖥️ Opening exam interface..."
    xdg-open http://localhost:30080 2>/dev/null || true
elif command -v open >/dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | 🖥️ Opening exam interface..."
    open http://localhost:30080 2>/dev/null || true
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ℹ️ Please open http://localhost:30080 in your browser"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') | 🎯 Exam Ready! Access at: http://localhost:30080"
echo "$(date '+%Y-%m-%d %H:%M:%S') | 📊 Status page at: http://localhost:8080"

sleep 1
touch /ready

# Keep container running
tail -f /dev/null