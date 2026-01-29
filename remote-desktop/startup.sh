#!/bin/bash

# Log startup
echo "Starting CKS Exam VNC service at $(date)"

# Resolve jumphost so both ckad9999 and cks-node01 work for SSH (exam instance)
JUMPHOST_IP=$(getent hosts jumphost 2>/dev/null | awk '{ print $1 }')
if [ -n "$JUMPHOST_IP" ]; then
  echo "$JUMPHOST_IP cks-node01" >> /etc/hosts 2>/dev/null || true
fi

echo "echo 'Use Ctrl + Shift + C for copying and Ctrl + Shift + V for pasting'" >> /home/candidate/.bashrc
echo "alias kubectl='echo \"kubectl not available here. Solve this question on the specified instance\"'" >> /home/candidate/.bashrc

# Run in the background - don't block the main container startup
python3 /tmp/agent.py &

exit 0 