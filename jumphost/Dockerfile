# Base Image
FROM ubuntu:22.04

# Switch to root user for installations
USER 0

# Update and install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    openssh-server \
    vim \
    bash-completion\
    nano \
    docker.io\
    jq

# Accept build-time architecture argument
ARG TARGETARCH

#install kubectl for x86_64 and ARM64 architectures
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl; \
    fi

# Install Trivy (needed for CKS image scanning - question 15)
RUN apt-get install -y wget apt-transport-https gnupg lsb-release && \
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - && \
    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install -y trivy

#override docker daemon to use cfg2group
RUN echo '{ "exec-opts": ["native.cgroupdriver=cgroupfs"] }' > /etc/docker/daemon.json

# Set up SSH server
RUN mkdir -p /var/run/sshd

# Generate SSH host keys
RUN ssh-keygen -A

# Disable SSH authentication (VERY INSECURE: USE WITH CAUTION)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication no/' /etc/ssh/sshd_config
RUN sed -i 's/#UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# Completely remove password requirement
RUN echo "root::0:0:root:/root:/bin/bash" > /etc/passwd

# Create a new user 'candidate' with Docker permissions
RUN useradd -m candidate

#disable password login for candidate user
RUN echo "candidate::0:0:candidate:/home/candidate:/bin/bash" > /etc/passwd
RUN echo "candidate:x:1000:1000:candidate:/home/candidate:/bin/bash" >> /etc/passwd

# Set up Minikube cluster on startup
RUN mkdir -p /home/candidate/.kube /home/candidate/.minikube
RUN chown -R candidate:candidate /home/candidate/.kube /home/candidate/.minikube
RUN chmod 755 /home/candidate/.kube
RUN chmod 755 /home/candidate/.minikube

# Create downloads directory (cri-dockerd will be downloaded during exam setup if needed)
RUN mkdir -p /home/candidate/downloads
RUN chown candidate:candidate /home/candidate/downloads
RUN chmod 755 /home/candidate/downloads

# Copy exam environment scripts
COPY scripts/prepare-exam-env.sh /usr/local/bin/prepare-exam-env
COPY scripts/cleanup-exam-env.sh /usr/local/bin/cleanup-exam-env

# Make scripts executable
RUN chmod +x /usr/local/bin/prepare-exam-env
RUN chmod +x /usr/local/bin/cleanup-exam-env

RUN mkdir -p /tmp/exam-env

# Expose SSH port
EXPOSE 22

RUN echo "export TERM=xterm" >> /home/candidate/.bashrc
RUN echo "export KUBECONFIG=/home/candidate/.kube/kubeconfig" >> /home/candidate/.bashrc
RUN echo "PS1='\[\e[32m\]\u@\h:\w\$ \[\e[0m\]'" >> /home/candidate/.bashrc

#set kubectl autocompletion
RUN echo "source /usr/share/bash-completion/bash_completion" >> /home/candidate/.bashrc && \
    echo "source <(kubectl completion bash)" >> /home/candidate/.bashrc && \
    echo "alias k=kubectl" >> /home/candidate/.bashrc && \
    echo "complete -F __start_kubectl k" >> /home/candidate/.bashrc

#start ssh service
RUN useradd -r -s /usr/sbin/nologin sshd
# RUN service ssh start

ENV CLUSTER_NAME=cluster

# Start SSH and Minikube on container start
CMD ["/bin/bash", "-c", "service ssh start && dockerd & tail -f /dev/null"]
