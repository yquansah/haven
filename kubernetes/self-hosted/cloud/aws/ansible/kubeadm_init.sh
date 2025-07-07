#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_KEY_PATH="${HOME}/.ssh/id_rsa"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "Error: SSH private key not found at $SSH_KEY_PATH"
  exit 1
fi

echo "Fetching EC2 instance IPs..."

# Get control plane IP
CONTROL_PLANE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Component,Values=control-plane-node" "Name=instance-state-name,Values=running" \
  --output text \
  --query "Reservations[0].Instances[0].PublicIpAddress")

# Get worker node IPs
WORKER_NODE_IPS=$(aws ec2 describe-instances \
  --filters "Name=tag:Component,Values=worker-node" "Name=instance-state-name,Values=running" \
  --output text \
  --query "Reservations[].Instances[].PublicIpAddress" | tr '\n' ' ')

# Get load balancer DNS name
LOAD_BALANCER_DNS=$(aws elbv2 describe-load-balancers \
  --names "yke-load-balancer" \
  --output text \
  --query "LoadBalancers[0].DNSName")

if [ -z "$CONTROL_PLANE_IP" ]; then
  echo "Error: No control plane node found"
  exit 1
fi

if [ -z "$WORKER_NODE_IPS" ]; then
  echo "Error: No worker nodes found"
  exit 1
fi

if [ -z "$LOAD_BALANCER_DNS" ]; then
  echo "Error: Load balancer not found"
  exit 1
fi

echo "Found control plane node: $CONTROL_PLANE_IP"
echo "Found worker nodes: $WORKER_NODE_IPS"
echo "Found load balancer: $LOAD_BALANCER_DNS"


# Step 1: Initialize the control plane
echo "Initializing Kubernetes control plane..."
ssh $SSH_OPTS -i "$SSH_KEY_PATH" ubuntu@$CONTROL_PLANE_IP <<EOF
sudo kubeadm init \
    --control-plane-endpoint="$LOAD_BALANCER_DNS:6443" \
    --apiserver-cert-extra-sans="$LOAD_BALANCER_DNS" \
    --pod-network-cidr="192.168.0.0/16" \
    --node-name="control-plane-0" \
    --ignore-preflight-errors=Swap

# Set up kubeconfig for ubuntu user
mkdir -p /home/ubuntu/.kube
rm /home/ubuntu/.kube/config
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Install Calico CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Generate join command
kubeadm token create --print-join-command > /tmp/join-command.txt
EOF

# Wait for load balancer port 6443 to be ready
echo "Waiting for load balancer port 6443 to be ready..."
while ! nc -z "$LOAD_BALANCER_DNS" 6443; do
  echo "Port 6443 on $LOAD_BALANCER_DNS is not ready yet. Waiting 5 seconds..."
  sleep 5
done
echo "Load balancer port 6443 is ready!"

# Step 2: Get the join command from control plane
echo "Retrieving join command from control plane..."
JOIN_COMMAND=$(ssh $SSH_OPTS -i "$SSH_KEY_PATH" ubuntu@$CONTROL_PLANE_IP 'cat /tmp/join-command.txt')

if [ -z "$JOIN_COMMAND" ]; then
  echo "Error: Failed to retrieve join command"
  exit 1
fi

echo "Join command: $JOIN_COMMAND"

# Step 3: Join worker nodes to the cluster
echo "Joining worker nodes to the cluster..."
for worker_ip in $WORKER_NODE_IPS; do
  echo "Joining worker node: $worker_ip"
  ssh $SSH_OPTS -i "$SSH_KEY_PATH" ubuntu@$worker_ip <<EOF
sudo $JOIN_COMMAND
EOF
  echo "Worker node $worker_ip joined successfully"
done

echo "Kubernetes cluster setup completed successfully!"
echo "To access the cluster, copy the kubeconfig from the control plane:"
echo "scp -i $SSH_KEY_PATH ubuntu@$CONTROL_PLANE_IP:~/.kube/config ~/.kube/config"
